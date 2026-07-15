# Plan: multimoneda, fuentes de ingreso y patrimonio en CAD

Plan de implementación para soportar ingresos y gastos en varias monedas, separar visualmente el
registro de ingresos, analizar ingresos por fuente y mostrar el patrimonio consolidado en CAD.

Este documento define producto, datos, UX, cálculos, migración y pruebas. No contiene una
implementación. Las fases deben ejecutarse en orden porque las pantallas y estadísticas dependen del
nuevo modelo financiero.

## Resultado esperado

Al terminar:

- Cada ingreso, gasto y gasto recurrente conserva su importe y moneda original.
- Registrar un ingreso usa una experiencia propia centrada en **fuente**, no en categoría de gasto.
- El usuario puede crear, editar y archivar fuentes como “Startup”, “Heladería” o “Mi app”.
- Cada movimiento indica en qué cuenta entró o salió el dinero.
- El Bank of Canada aporta una tasa diaria de referencia, almacenada una sola vez por día.
- Los reportes históricos usan la tasa guardada para la fecha del movimiento.
- El Home valora los saldos actuales con la tasa más reciente y los presenta en CAD.
- El Dashboard muestra ingresos por fuente, evolución, mezcla de monedas e ingreso neto del período.
- Una conversión entre cuentas USD y CAD se registra como transferencia, nunca como ingreso nuevo.

## Estado actual y gaps confirmados

- `transactions.currency` ya existe, pero Quick Entry fuerza siempre `households.currency`.
- `subscriptions.currency` ya existe, pero su formulario también fuerza la moneda del hogar.
- Gastos e ingresos comparten `QuickEntrySheet`; ambos muestran responsable, prioridad y categoría.
- No existe una entidad para fuentes de ingreso.
- No existen cuentas financieras ni saldos por cuenta.
- `TransactionType.transfer` existe, pero todavía no modela origen, destino ni dos monedas.
- `DashboardSummary` suma minor units de monedas distintas como si fueran equivalentes.
- El “saldo disponible” actual es `ingresos − gastos` del mes; no representa patrimonio.
- Insights calcula únicamente gasto y presupuesto en una sola moneda.
- `Money` impide correctamente sumar monedas diferentes; las agregaciones actuales evitan esa
  protección al sumar directamente `minorUnits`.

## Decisiones de producto

1. **CAD es la moneda de reporte del hogar** para este alcance. Mantener el dato configurable en el
   modelo permite reutilizar la arquitectura en otros países, pero el hogar del usuario se configura
   en CAD.
2. **Nunca convertir destructivamente.** El importe y la moneda originales son la fuente de verdad.
3. **Dos criterios de conversión:**
   - patrimonio actual: última tasa disponible;
   - estadísticas históricas: tasa fijada en la fecha del movimiento.
4. **La fuente sustituye a la categoría solo para ingresos.** Las categorías siguen siendo el eje de
   gastos y presupuestos.
5. **La cuenta es obligatoria para nuevos movimientos.** Sin cuenta no puede calcularse un saldo real.
6. **Transferencias no afectan ingresos, gastos ni flujo neto.** Solo mueven valor entre cuentas.
7. **La tasa del Bank of Canada es indicativa.** Si existe un cargo o conversión real del banco, el
   importe real prevalece.
8. **No llamar “patrimonio” a una suma incompleta.** El Home mostrará “Saldo total” mientras solo haya
   activos. Podrá mostrar “Patrimonio neto” cuando se soporten y registren pasivos.

## Invariantes financieras

- Un movimiento tiene exactamente una moneda original.
- Un ingreso tiene `income_source_id` y no necesita `category_id`.
- Un gasto puede tener `category_id` y no tiene `income_source_id`.
- Un movimiento normal pertenece a una cuenta cuya moneda coincide con la moneda efectivamente
  acreditada o debitada.
- `amount_reporting` se calcula una vez para el reporte histórico y no cambia al variar el mercado.
- El saldo actual se deriva del saldo inicial más movimientos confirmados y patas de transferencias.
- USD → CAD multiplica por la tasa; CAD → USD divide por la tasa.
- Los cálculos monetarios redondean a los decimales de la moneda destino y nunca usan `double` como
  representación persistida.
- Una tasa debe incluir moneda, fecha efectiva, valor, fuente y momento de consulta.
- No se suma `Money` de monedas distintas sin pasar explícitamente por el conversor.

---

## Fase 0 — Contratos y casos de aceptación

Antes de migrar datos, fijar ejemplos que se usarán en todas las pruebas:

### Escenario base

- Cuenta “Banco CAD”: saldo inicial `10,000 CAD`.
- Cuenta “Wise USD”: saldo inicial `2,000 USD`.
- Tasa actual: `1 USD = 1.37 CAD`.
- Ingreso Startup: `3,500 CAD`.
- Ingreso Heladería: `620 CAD`.
- Ingreso Mi app: `900 USD`.
- Alquiler recurrente: `1,890 CAD`.
- ChatGPT recurrente: `20 USD`, pagado finalmente como `28.14 CAD` desde tarjeta CAD.

### Resultados que deben ser reproducibles

- Las fuentes suman y muestran cada moneda original correctamente.
- El reporte histórico de Mi app conserva la conversión fijada el día del ingreso.
- El valor actual de Wise cambia al actualizar la tasa, sin modificar sus movimientos.
- ChatGPT conserva `20 USD` como precio facturado y permite registrar `28.14 CAD` como cargo real.
- Transferir USD a CAD no incrementa el total de ingresos.
- Un fin de semana utiliza la tasa del último día hábil y lo comunica en UI.

**Criterio de salida:** fixtures documentados y terminología aprobada en ES, EN y PT.

---

## Fase 1 — Modelo de datos multimoneda y cuentas

Crear las migraciones con Supabase CLI y revisar las políticas RLS existentes antes de aplicar.

### 1.1 Tabla `accounts`

Campos propuestos:

- `id`, `household_id`, `name`.
- `currency` ISO 4217.
- `kind`: `cash`, `checking`, `savings`, `credit_card`, `loan`, `investment`, `other`.
- `balance_nature`: `asset` o `liability`.
- `opening_balance numeric(14,2)`.
- `opening_balance_at timestamptz`.
- `icon_name`, `color_hex`, `is_default`, `is_archived`.
- `created_at`, `updated_at`.

Reglas:

- Una cuenta archivada conserva todo su historial.
- Como máximo una cuenta predeterminada activa por hogar y moneda.
- La moneda no se puede cambiar cuando la cuenta ya tiene movimientos.
- Habilitar RLS y autorizar únicamente a miembros del hogar correspondiente.

### 1.2 Extensión de `transactions`

Añadir:

- `account_id`.
- `reporting_currency`.
- `exchange_rate_to_reporting numeric(20,10)`.
- `exchange_rate_date date`.
- `exchange_rate_source`.
- `amount_reporting numeric(14,2)`.
- `transfer_group_id` y `transfer_direction` para las dos patas de una transferencia.

Reglas de base de datos:

- El hogar de cuenta y transacción debe coincidir.
- Transferencia: grupo y dirección obligatorios; fuente y categoría nulos.
- Índices por `(household_id, occurred_at)`, `account_id` y `transfer_group_id`.

No volver `account_id` obligatorio hasta completar el backfill.

### 1.3 Migración de datos existentes

Por cada hogar:

1. Crear una cuenta predeterminada en la moneda actual del hogar.
2. Asignar a ella las transacciones existentes.
3. Tratar sus importes históricos como ya expresados en la moneda del hogar:
   `rate = 1`, `reporting_currency = households.currency` y
   `amount_reporting = amount`.
4. Para pasar un hogar existente de USD a CAD, ejecutar una migración explícita: obtener la tasa
   histórica de cada fecha, recalcular el snapshot en CAD y solo entonces cambiar la moneda de
   reporte. Nunca relabelar un importe USD como CAD con tasa 1.
5. Mantener la moneda de reporte bloqueada después de tener datos, salvo mediante esa migración
   controlada.
6. Tras validar que no quedan filas huérfanas, hacer `account_id` obligatorio para movimientos nuevos.

### 1.4 Dominio Flutter

- Añadir `FinancialAccount` y su mapper/repositorio/providers.
- Extender `Transaction` con cuenta, fuente y snapshot de conversión.
- Crear un objeto `FxRate` y un servicio puro `CurrencyConverter`.
- Mantener `Money` como importe original; modelar la conversión como otro `Money`, no como una
  mutación del original.
- Definir una política única de redondeo y probar CAD, USD y monedas sin centavos como JPY.

**Criterio de salida:** migración reversible, RLS probada, datos viejos visibles y ninguna suma
implícita entre monedas.

---

## Fase 2 — Tasas de cambio diarias

### 2.1 Fuente y almacenamiento

Usar Bank of Canada Valet como fuente primaria. Para USD/CAD:

`https://www.bankofcanada.ca/valet/observations/FXUSDCAD/json?recent=1`

Crear `exchange_rates` con:

- `rate_date`.
- `foreign_currency`.
- `reporting_currency` (`CAD` en este alcance).
- `rate numeric(20,10)` entendido como CAD por una unidad extranjera.
- `source` (`bank_of_canada`).
- `retrieved_at`.
- `raw_observation_date` si difiere del día de consulta.
- restricción única por fecha, par y fuente.

La tabla puede ser global, no por hogar. Lectura autenticada; escritura solo desde backend. No
exponer una clave privilegiada al cliente.

### 2.2 Actualización automática

- Ejecutar una Edge Function programada una vez al día después de las 17:00 ET.
- Validar HTTP, esquema JSON, fecha, valor positivo y que la observación no retroceda.
- Hacer `upsert` idempotente.
- Guardar el último valor válido si la fuente falla.
- Registrar error observable sin bloquear el uso de la app.
- Durante la implementación, verificar changelog y documentación vigente de Supabase Cron/Edge
  Functions antes de elegir `pg_cron`, Scheduled Functions u otro mecanismo soportado.

### 2.3 Resolución de tasas

`CurrencyConverter` debe resolver en este orden:

1. Tasa real introducida por el usuario para una conversión/cargo.
2. Tasa exacta de la fecha del movimiento.
3. Última tasa anterior disponible (fin de semana/festivo).
4. Última tasa cacheada, marcada como desactualizada.
5. Si nunca hubo tasa, impedir solo la conversión estimada; permitir guardar el importe original y
   completar el snapshot posteriormente mediante un proceso de reparación.

Guardar `is_estimated`/procedencia en el snapshot o derivarlo de los campos de tasa.

### 2.4 Alternativa

Preparar una interfaz de proveedor para incorporar Frankfurter como respaldo o para monedas que el
Bank of Canada no publique. No implementar fallback externo en el primer corte si CAD/USD cubre el
producto inicial.

**Criterio de salida:** una sola consulta diaria, cache persistente, fines de semana resueltos y
conversión determinista con pruebas.

---

## Fase 3 — Fuentes de ingreso

### 3.1 Tabla `income_sources`

Campos:

- `id`, `household_id`, `name`.
- `type`: `employment`, `business`, `freelance`, `investment`, `benefit`, `other`.
- `default_currency`.
- `default_account_id`.
- `icon_name`, `color_hex`.
- `is_archived`.
- `created_at`, `updated_at`.

Reglas:

- El nombre es obligatorio y se muestra tal como lo escribió el usuario.
- Evitar duplicados activos por nombre dentro del hogar, ignorando mayúsculas y espacios extremos.
- Archivar, no borrar, si existe historial.
- RLS por pertenencia al hogar.

En la misma migración, añadir `transactions.income_source_id` con FK, índice y validaciones:

- El hogar de fuente y transacción debe coincidir.
- Ingreso: fuente permitida, categoría ignorada por la UI.
- Gasto y transferencia: fuente nula.

### 3.2 Feature Flutter `income_sources`

Crear siguiendo las convenciones actuales:

- `data`: mapper y repositorio Supabase/mock.
- `application`: providers y controller CRUD.
- `presentation`: selector, formulario de nueva fuente y pantalla de administración.

La fuente recuerda moneda y cuenta predeterminadas, pero el usuario puede cambiarlas en cada ingreso.

### 3.3 Compatibilidad histórica

- Ingresos antiguos sin fuente aparecen como “Sin fuente”.
- Ofrecer posteriormente una acción de recategorización masiva; no bloquear el lanzamiento por ella.
- No reutilizar `categories`: presupuestos, colores y semántica de gastos deben seguir separados.

**Criterio de salida:** crear “Startup”, “Heladería” y “Mi app”, seleccionarlas al registrar y
archivarlas sin perder estadísticas.

---

## Fase 4 — Tres experiencias de registro

El botón `+` debe abrir un selector breve:

- Registrar gasto.
- Registrar ingreso.
- Transferir entre cuentas.

Cada opción abre un formulario especializado. Evitar mantener un único formulario lleno de campos
condicionales difíciles de entender.

### 4.1 Formulario de gasto

Mantener y refinar el flujo actual:

- Cantidad y moneda.
- Cuenta desde la que se pagó.
- Categoría.
- Prioridad.
- Responsable.
- Fecha del gasto.
- Nota y escaneo de recibo.
- Conversión aproximada a CAD cuando corresponda.

El escaneo debe extraer o permitir confirmar la moneda del recibo; dejar de asumir automáticamente
la moneda del hogar.

### 4.2 Formulario de ingreso

Diseño propio, sin categoría, prioridad ni escaneo de recibo como elementos principales.

Campos obligatorios:

- Cantidad recibida.
- Moneda.
- Fuente de ingreso.
- Cuenta donde entró.
- Fecha efectiva de recepción; por defecto, hoy.

Campos opcionales:

- Descripción/nota.
- Importe bruto, comisiones o retenciones en una sección avanzada.
- Referencia externa.

Comportamiento:

- `+ Nueva fuente` abre un subflujo y devuelve la nueva fuente ya seleccionada.
- Seleccionar una fuente propone su moneda y cuenta habituales.
- Cambiar la cuenta valida que la moneda recibida coincida; si no coincide, iniciar una conversión
  explícita o pedir el importe efectivamente acreditado.
- Mostrar `900 USD ≈ 1,233 CAD` como referencia, nunca como importe original.

### 4.3 Gasto recurrente

Actualizar `SubscriptionFormSheet`:

- Selector de moneda independiente de la moneda del hogar.
- Cuenta habitual de pago.
- Precio facturado original (ej. `20 USD`).
- Estimación de próximo cargo en CAD.
- Al confirmar un cobro, permitir registrar el importe real debitado (ej. `28.14 CAD`).
- El precio recurrente no cambia cuando el banco aplica una tasa diferente cada mes.

### 4.4 Transferencia y conversión

- Cuenta origen y cantidad enviada.
- Cuenta destino y cantidad recibida.
- Tasa real calculada a partir de ambos importes.
- Comisión opcional, registrada como gasto separado o componente explícito según la decisión de
  dominio final.
- Crear dos patas atómicas con el mismo `transfer_group_id`.
- En historial, renderizar ambas como una sola operación.

**Criterio de salida:** cada flujo muestra solo campos relevantes y ninguna conversión cuenta como
ingreso o gasto por accidente.

---

## Fase 5 — Saldos y patrimonio en Home

### 5.1 Motor de saldos

Por cuenta:

`saldo = saldo inicial + ingresos - gastos + transferencias entrantes - transferencias salientes`

- Usar solo movimientos confirmados.
- Calcular en la moneda nativa de la cuenta.
- Pasivos invierten su contribución al patrimonio.
- Excluir movimientos anteriores a `opening_balance_at` si el saldo inicial ya los incorpora.

### 5.2 Conversión para valoración actual

- Convertir cada saldo usando la tasa más reciente disponible.
- Guardar en el read-model fecha y antigüedad de la tasa.
- No persistir esa valoración como si fuera una transacción.
- Si falta una tasa, mostrar el saldo original y un estado parcial; no fingir un total completo.

### 5.3 Jerarquía visual del Home

Bloque principal:

- “Saldo total” o “Patrimonio neto”, según datos soportados.
- Total en CAD.
- Desglose: saldo CAD y saldo USD con equivalente aproximado.
- Tasa y fecha: `1 USD = 1.3700 CAD · actualizada hoy`.
- Indicador si se usa una tasa anterior.

Debajo:

- Ingresos del mes en CAD histórico.
- Gastos del mes en CAD histórico.
- Flujo neto del mes.
- Acceso al detalle de cuentas.

Reemplazar la semántica actual de `DashboardSummary.balance`: el flujo mensual y el patrimonio son
dos métricas distintas y deben tener nombres/campos separados.

**Criterio de salida:** el total de Home coincide con la suma manual de cuentas del escenario base y
no cambia los ingresos históricos cuando cambia la tasa actual.

---

## Fase 6 — Estadísticas de ingresos en Dashboard/Insights

Ampliar `MonthInsights` o crear un read-model específico de ingresos. No colocar agregaciones dentro
de widgets.

### 6.1 Resumen del período

Con selector de período:

- Ingresos.
- Gastos.
- Flujo neto.
- Comparación con período anterior.

Todas estas cifras usan `amount_reporting` histórico en CAD. Transferencias quedan excluidas.

### 6.2 Ingresos por fuente

- Gráfico de dona o barras con importe y porcentaje.
- Top fuentes y agrupación “Otros” cuando sea necesario.
- Lista con moneda original cuando una fuente opera en una sola moneda.
- Si una fuente mezcla monedas, mostrar total CAD y desglose al abrirla.
- Tap en una fuente filtra el historial por `income_source_id`.

### 6.3 Evolución

- Serie de 6 meses, apilada por fuente.
- Comparación de cada fuente contra mes anterior.
- Estado vacío útil para ingresos sin fuente.
- No concluir “crecimiento” con períodos incompletos sin indicarlo.

### 6.4 Exposición por moneda

Separar:

- patrimonio actual por moneda, basado en cuentas;
- ingresos del período por moneda, basado en movimientos.

No combinar ambos porcentajes en un mismo gráfico.

### 6.5 Previsión, segunda entrega

Después del núcleo:

- Próximos ingresos recurrentes.
- Próximos gastos recurrentes.
- Flujo estimado de 30 días.

Las previsiones se etiquetan como estimadas y nunca alteran saldos hasta que se confirman.

**Criterio de salida:** Dashboard responde cuánto entró, de dónde vino, cómo evoluciona y en qué
monedas, manteniendo separado el patrimonio.

---

## Fase 7 — Historial, filtros y edición

- Mostrar código de moneda en todos los importes cuando el hogar tenga más de una moneda.
- Añadir filtros por tipo, cuenta, moneda y fuente de ingreso.
- Para ingresos, sustituir el chip de categoría por el de fuente.
- Mostrar importe original y equivalente histórico en el detalle.
- Mostrar fuente, cuenta, fecha de tasa y procedencia.
- Editar importe, moneda o fecha debe recalcular el snapshot histórico de manera explícita.
- Editar una transferencia actualiza ambas patas atómicamente.
- Eliminar una fuente usada debe convertirse en archivar.
- Eliminar una cuenta con movimientos debe estar prohibido; solo se archiva.

**Criterio de salida:** cualquier cifra agregada puede rastrearse hasta movimientos y tasas visibles.

---

## Fase 8 — Localización, accesibilidad y estados de error

- Añadir todas las cadenas a ES, EN y PT; nada de textos hardcodeados en los nuevos formularios.
- Mostrar siempre códigos ISO (`CAD`, `USD`) junto a símbolos ambiguos como `$`.
- Lectores de pantalla deben anunciar importe, moneda y si la conversión es aproximada.
- Verificar contraste de colores de fuentes y no depender solo del color.
- Estados específicos:
  - sin fuentes;
  - sin cuentas;
  - tasa no disponible;
  - tasa desactualizada;
  - conversión pendiente;
  - sin ingresos en el período;
  - datos históricos sin fuente.

---

## Estrategia de pruebas

### Base de datos

- Migración y backfill sobre un hogar con datos existentes.
- RLS: aislamiento entre hogares para cuentas y fuentes.
- Usuarios del mismo hogar pueden leer/escribir según el modelo actual.
- Nadie desde el cliente puede insertar/modificar `exchange_rates`.
- Constraints de tipo/fuente/categoría/transferencia.
- Idempotencia del upsert diario de tasas.
- Prueba de dos patas de transferencia dentro de una sola transacción SQL.
- Ejecutar linter, tests DB y advisors de Supabase.

### Dominio

- Conversión USD/CAD y CAD/USD con redondeo.
- Misma moneda devuelve tasa 1.
- Resolución de fin de semana y tasa desactualizada.
- Snapshot histórico inmutable.
- Saldo de activos y pasivos.
- Transferencias excluidas de ingresos/gastos.
- Agregación por fuente y por moneda.
- Prohibición de sumar monedas distintas sin conversión.

### Controllers/repositorios

- Crear/editar/archivar fuente.
- Registrar ingreso con fuente, cuenta, fecha y moneda.
- Registrar gasto recurrente USD desde cuenta CAD con cargo real.
- Fallos de API de tasas no pierden el movimiento original.
- Invalidación de providers/Realtime después de cada escritura.

### Widget/golden

- Selector inicial `Gasto / Ingreso / Transferencia`.
- Formulario de ingreso sin categoría/prioridad.
- Creación inline de una fuente.
- Selector de moneda en ingreso, gasto y recurrente.
- Home con CAD + USD, tasa vigente y tasa desactualizada.
- Dashboard con 1, 3 y más de 5 fuentes.
- ES, EN, PT; tema claro/oscuro; pantalla pequeña y texto grande.

### Manual end-to-end

Reproducir el escenario de la Fase 0 y contrastar cada total con cálculo manual. Cambiar la tasa del
día siguiente y confirmar que solo cambia la valoración actual, no los reportes históricos.

---

## Orden recomendado de entregas y commits

1. `feat(accounts): add household financial accounts and backfill`
2. `feat(fx): persist daily CAD reference rates`
3. `feat(money): add explicit currency conversion snapshots`
4. `feat(income-sources): add household income sources`
5. `refactor(quick-entry): split expense income and transfer flows`
6. `feat(income): add dedicated income entry experience`
7. `feat(subscriptions): support original billing currency`
8. `feat(transfers): add atomic cross-currency transfers`
9. `feat(home): show account-based total in CAD`
10. `feat(insights): add income-source and currency analytics`
11. `feat(transactions): add account source and currency filters`
12. `test(multicurrency): cover migration conversion and reporting flows`

Cada entrega debe cerrar con:

- `flutter gen-l10n` si cambian cadenas.
- Regeneración de Freezed/JSON cuando cambien modelos.
- `dart format`.
- `flutter analyze`.
- `flutter test`.
- Tests/lint/advisors de Supabase cuando cambie base de datos.
- Comprobación manual del criterio de aceptación de la fase.

## Corte MVP recomendado

Para entregar valor sin mezclar todo en una sola release:

### MVP 1 — Registro correcto

- Cuentas.
- Moneda por movimiento.
- Tasa diaria CAD/USD.
- Fuentes de ingreso.
- Formulario de ingreso independiente.
- Moneda en gastos recurrentes.

### MVP 2 — Lectura financiera

- Transferencias y conversiones reales entre cuentas.
- Saldo total en CAD basado en cuentas.
- Ingresos/gastos/flujo neto multimoneda.
- Ingresos por fuente y evolución.
- Filtros y detalle histórico.

### MVP 3 — Operación avanzada

- Diferencia entre precio facturado y cargo bancario.
- Pasivos y patrimonio neto completo.
- Proyecciones de 30 días e ingresos recurrentes.

## Definición final de terminado

- No existe ningún cálculo que sume directamente importes de monedas distintas.
- Se puede registrar `20 USD` de ChatGPT, `1,890 CAD` de alquiler y `900 USD` de Mi app.
- La fuente “Mi app” aparece separada de “Startup” y “Heladería” en estadísticas.
- Home presenta un total CAD rastreable a cuentas y tasas.
- Los valores históricos permanecen estables al cambiar el mercado.
- Las transferencias no duplican ingresos.
- Migración, RLS, errores, offline básico y localización están cubiertos.
- Documentación de arquitectura y Dashboard actualizada para reflejar la nueva semántica.
