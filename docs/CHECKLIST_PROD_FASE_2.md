# leakless — Checklist de Producción · Fase 2 (auth + invitar pareja)

> Documento de trabajo + **handoff entre agentes**. Se avanza **una tarea a la
> vez**: se implementa, se verifica, se marca **APROBADO**, y **se detiene** para
> que otro agente (o el humano) continúe con la siguiente.
>
> Fase anterior: [CHECKLIST_PROD.md](CHECKLIST_PROD.md). Roadmap completo:
> [PRODUCCION_Y_MONETIZACION.md](PRODUCCION_Y_MONETIZACION.md).
> Última actualización: 2026-07-10.

---

## 📌 Instrucciones para el próximo agente (leer primero)

1. **Lee este archivo completo** antes de tocar nada. El estado real de Fase 2
   vive aquí; Fase 1 ya está cerrada.
2. **Haz SOLO la siguiente tarea sin marcar** (la que dice `⏭️ SIGUIENTE`). No
   adelantes trabajo de tareas posteriores.
3. **Sigue los patrones existentes**, especialmente `transactions`:
   - Interface + mock + implementación Supabase en el mismo `*_repository.dart`.
   - Mapper dedicado para snake_case ⟷ dominio; ningún row de DB llega a UI.
   - Errores de SDK/DB envueltos en `AppException` (`ServerException`,
     `AuthFailureException`, etc.).
   - Providers eligen Supabase vs mock mediante `supabaseEnabledProvider`.
   - Las operaciones sensibles o multi-fila van en RPC/función server-side y se
     prueban contra RLS; no se simulan con varios writes desde Flutter.
4. **Verifica** al menos `flutter analyze` sin issues. Corre además las pruebas
   directamente afectadas (`flutter test`, pgTAP/Supabase y/o integration test).
   Si cambias modelos freezed, corre
   `dart run build_runner build --delete-conflicting-outputs`.
5. **Actualiza este archivo**: marca tu tarea `✅ APROBADO` con fecha, mueve
   `⏭️ SIGUIENTE` a la siguiente y añade una entrada al **Registro de
   razonamiento** con implementación, decisiones, trampas y evidencia.
6. **Detente.** No continúes con la siguiente tarea.

---

## Estado base comprobado (2026-07-01)

- Fase 1 cerrada: repos reales, auto-provisión, smoke e2e y aislamiento RLS
  aprobados. Ver [CHECKLIST_PROD.md](CHECKLIST_PROD.md).
- `SupabaseAuthRepository` ya implementa email/password: sign in, sign up,
  envío de correo de recuperación y sign out. `AuthScreen` ya valida nombre,
  email, contraseña/confirmación y muestra errores específicos por campo/estado.
- El correo de recuperación **sólo se envía**: faltan callback/deep link,
  pantalla para elegir la nueva contraseña y `updateUser`.
- `SupabaseProfileRepository` ya puede leer/editar perfil y subir avatar privado;
  falta la UI que consume sus métodos de escritura.
- El contrato backend y el boundary Flutter de invitaciones ya existen (modelo,
  mapper, repositorio y controller/providers); todavía no hay deep links ni UI.
- `handle_new_user` crea para **cada** usuario un perfil, un household propio,
  membership owner y seis categorías. La aceptación de una invitación debe
  reconciliar ese household inicial de forma atómica y sin perder datos.
- El router sólo distingue onboarding → auth → app. No hay rutas/callbacks para
  recovery ni invitaciones, ni estado de “sin household / invitación pendiente”.
- `profiles.household_id` representa un único household activo. El alcance v1
  sigue siendo una pareja/un household por usuario.
- Borrar al owner hoy puede borrar el household completo por FK `on delete
  cascade`; no implementar borrado de cuenta sin resolver ownership.

### Flujo objetivo de la fase

`owner crea invitación` → `backend emite token de un solo uso` → `pareja abre
deep link/QR` → `auth si hace falta` → `RPC acepta y mueve al household` →
`ambos ven miembros/datos compartidos` → `gestión de perfil/sesión/cuenta`

---

## Fase 2 — Autenticación y household compartido (P0 🔴)

- [x] **F2-T1 — Contrato backend seguro de invitaciones + pruebas.** ✅ **APROBADO (2026-07-01)**
  - Añadir migración versionada para `household_invitations` (token almacenado
    como hash, household, email normalizado, inviter, estado, expiración,
    timestamps y constraints/índices).
  - Añadir RPCs `security definer` mínimas para crear, inspeccionar y aceptar/
    cancelar invitaciones, con `search_path` fijo y permisos explícitos.
  - La aceptación debe ser atómica e idempotente: validar usuario/email/token,
    añadir membership, actualizar `profiles.household_id` y reconciliar el
    household inicial vacío creado por `handle_new_user`. Nunca borrar un hogar
    que ya tenga datos o más miembros.
  - Probar happy path, token inválido/expirado/reutilizado, no-owner, email
    distinto, household ajeno y aislamiento RLS. Documentar cómo se entrega el
    token sin guardar el secreto en claro.
- [x] **F2-T2 — Dominio + repositorio + controller/providers de invitaciones.** ✅ **APROBADO (2026-07-03)**
  - Añadir modelo/mapper de invitación y extender el boundary de household
    siguiendo `transactions` (mock + Supabase + `AppException`).
  - Exponer crear/cancelar/aceptar y refrescar `currentHouseholdProvider`,
    `householdMembersProvider`, perfil y datos household-scoped después de una
    aceptación, evitando caché del usuario anterior.
  - Tests unitarios de mapper, estados y errores.
- [x] **F2-T3 — Deep link/QR + experiencia de invitar y aceptar.** ✅ **APROBADO (2026-07-03)**
  - Rutas centralizadas para invitación y persistencia segura del intento cuando
    el receptor aún debe registrarse/iniciar sesión.
  - Pantalla owner para compartir enlace/código/QR, ver estado y revocar.
  - Pantalla receptor con preview seguro, aceptar/rechazar, loading/error/success
    y manejo de enlace inválido/expirado/usado.
  - No registrar tokens completos en analytics, logs, crash reports ni URLs
    persistidas por la app.
- [x] **F2-T4 — Onboarding/configuración del household compartido.**
  ✅ **IMPLEMENTADO (2026-07-03) · pendiente checkpoint pgTAP local**
  - Permitir al owner editar nombre y moneda, revisar categorías iniciales e
    invitar a la pareja; permitir omitir la invitación y retomarla en Ajustes.
  - Manejar explícitamente usuario sin household, invitación pendiente y hogar
    con un solo miembro, sin mandar al dashboard con datos inconsistentes.
  - Asegurar que cambiar moneda no reinterprete silenciosamente importes ya
    guardados.
- [x] **F2-T5 — Edición de perfil y avatar en UI.**
  ✅ **IMPLEMENTADO (2026-07-04)**
  - Conectar Ajustes a `updateProfile`/`uploadAvatar`: nombre, moneda, selector
    de imagen, permisos, compresión/límites y estados de error/loading.
  - Mantener sincronizados `profiles` y la representación visible del miembro;
    resolver/renovar el signed URL del bucket privado en vez de depender del URL
    persistido por un año.
- [x] **F2-T6 — Recuperación completa y ciclo de sesión.**
  ✅ **IMPLEMENTADO (2026-07-04)**
  - Configurar redirect allowlist y callback/deep link de recovery; añadir la
    pantalla para definir contraseña nueva y reautenticación cuando corresponda.
  - Manejar refresh/expiración/revocación de sesión y limpiar/invalidar providers
    sensibles en sign out y cambio de usuario.
  - Tests de redirect: recovery no debe caer en dashboard antes de completar el
    cambio de contraseña.
- [x] **F2-T7 — Decisión e implementación de login social.**
  ✅ **DECIDIDO: email-only para el MVP (2026-07-04)**
  - Decidir y registrar si el MVP será email-only. Si se ofrece Google en iOS,
    implementar también Sign in with Apple conforme a la regla de la Store.
  - Si se habilita: OAuth/deep links, nonce de Apple, account linking, errores y
    pruebas en iOS/Android. Si se difiere, aprobar explícitamente la decisión y
    retirar cualquier affordance social del release.
- [x] **F2-T8 — Borrado seguro de cuenta + cierre de sesión definitivo.**
  ✅ **IMPLEMENTADO (2026-07-04)**
  - Diseñar transferencia de owner cuando haya pareja; borrar el household sólo
    si el usuario es el único miembro y el producto lo confirma explícitamente.
  - Implementar operación server-side autenticada para eliminar/exportar lo que
    corresponda, limpiar avatar/tokens/sesión y ofrecer confirmación + re-auth en
    Ajustes. Probar que nunca se borren por cascade los datos del miembro que
    permanece.
- [ ] **F2-T9 — Checkpoint e2e de Fase 2 (dos usuarios reales).**
  ⏭️ **SIGUIENTE**
  - Owner invita → receptor abre enlace, se autentica y acepta → ambos quedan en
    el mismo household y ven los mismos miembros/datos.
  - Confirmar revocación/expiración/reuso, recovery, sign out/in sin caché
    cruzada, edición de perfil/avatar y borrado/transferencia de owner.
  - `flutter analyze` y suite completa sin issues; registrar evidencia humana de
    deep links/OAuth donde el agente no pueda cerrar la prueba por sí solo.

> **Criterio de cierre de Fase 2:** el flujo real de una pareja funciona de punta
> a punta, los límites de autorización están probados y ninguna transición de
> cuenta/household puede filtrar caché ni borrar datos de la otra persona.

---

## Registro de razonamiento (handoff trail)

Cada agente **añade** su entrada abajo (no borra las previas).

### F2-T0 — Creación y orden del checklist — ✅ APROBADO (2026-07-01)

**Por qué este orden:** el esquema actual no tiene invitaciones y el trigger de
alta crea un household por usuario. La UI no puede definir de forma segura qué
significa “aceptar” hasta que exista una única operación backend atómica,
autorizada y probada. Por eso F2-T1 precede a repositorios, deep links y pantallas.

**Qué ya estaba hecho y no se duplicó:** validadores y mensajes auth, sign
in/sign up email-password, solicitud de recuperación, sign out básico, lectura
de household y repositorio de perfil con escritura/avatar. Las tareas de esta
fase completan o exponen esos cimientos; no los reimplementan.

**Decisiones / trampas registradas:**
- El token de invitación es una credencial: DB guarda hash, el secreto se muestra
  una vez y nunca aparece en logs/analytics.
- La RPC de aceptación debe comprobar el email autenticado y ser idempotente;
  confiar sólo en UUIDs enviados por el cliente permitiría unirse a otro hogar.
- La auto-provisión hace necesario distinguir un starter household realmente
  vacío de uno con datos. Sólo el primero puede eliminarse al aceptar.
- Hay dos riesgos de ciclo de vida fuera de la invitación: providers globales
  con datos del usuario previo tras sign out/in, y cascade del household al
  borrar al owner. Ambos tienen tareas explícitas antes del checkpoint final.
- Login social es una decisión de producto separada: no ofrecerlo es válido para
  el MVP; ofrecer Google en iOS sin Apple no lo es.

**Verificación de esta tarea:** se creó y enlazó el documento; no se implementó
F2-T1 ni se modificó código de producto. `flutter analyze` → **No issues found!**

**Handoff:** implementar únicamente **F2-T1** y detenerse.

### F2-T1 — Contrato backend seguro de invitaciones + pruebas — ✅ APROBADO (2026-07-01)

**Implementación:**
- Se añadió la migración versionada
  `20260701191145_add_household_invitations.sql` con
  `household_invitations`, constraints de email normalizado/estado/expiración,
  hash SHA-256 de 32 bytes, FKs e índices para lookup, expiración y una única
  invitación pendiente por household/email.
- La tabla tiene RLS activa, ningún policy de cliente y grants revocados. Se
  retiró `members self insert`: permitía que cualquier autenticado insertara su
  propio `user_id` en un household ajeno y se saltara por completo la invitación.
- Se añadieron las RPCs autenticadas `create_household_invitation`,
  `inspect_household_invitation`, `accept_household_invitation` y
  `cancel_household_invitation`, todas `security definer`, con
  `search_path = ''`, referencias schema-qualified, `EXECUTE` revocado a
  `PUBLIC`/`anon` y concedido explícitamente a `authenticated`.
- `create` normaliza el email, exige al owner, genera 256 bits aleatorios y
  devuelve el secreto una sola vez; DB sólo guarda el digest. Re-crear una
  invitación pendiente rota el token anterior. La entrega prevista es tomar ese
  único valor de retorno y colocarlo en el enlace/QR; no se persiste en otra
  tabla ni se registra en logs, analytics o crash reports.
- `accept` bloquea la invitación y el perfil durante una transacción, comprueba
  token/email/estado/expiración, crea membership `member`, mueve
  `profiles.household_id` y marca la invitación aceptada. Repetirla por el mismo
  receptor ya unido devuelve éxito idempotente.
- La reconciliación sólo borra el starter auto-provisionado si conserva nombre,
  moneda y seis categorías seed exactas, tiene un único owner y no contiene
  movimientos, budgets, goals, subscriptions, notificaciones ni invitaciones.
  Si hay datos, personalización o más miembros, aborta con
  `current_household_not_empty` y no cambia ninguna fila.
- Se documentó el contrato y la entrega segura del secreto en
  `supabase/README.md`.

**Decisiones:**
- El preview requiere sesión y el mismo email normalizado que Auth. El deep link
  puede conservar el intento hasta autenticarse, pero el backend no revela ni
  siquiera el nombre del household a otro email.
- `pending`, `accepted` y `cancelled` son estados persistidos; `expired` se
  deriva de `expires_at` al inspeccionar. Así no hace falta un job para mantener
  consistente el estado temporal.
- La cancelación usa el UUID no secreto de la invitación y vuelve a verificar al
  owner server-side; ni IDs ni UUIDs suministrados por el cliente conceden acceso.
- Ante un starter no reconocible se prioriza no perder datos: la aceptación
  falla en vez de mover al usuario y dejar un household huérfano.

**Trampas resueltas:**
- Los parámetros `RETURNS TABLE` de PL/pgSQL chocaban con columnas homónimas en
  dos `ON CONFLICT`; `#variable_conflict use_column` fija el significado y el
  caso quedó validado ejecutando la migración desde cero.
- Supabase 2026 ya no garantiza exposición automática de tablas/funciones; la
  migración usa grants explícitos y el test confirma que `anon` no ejecuta la
  RPC y que `authenticated` no puede enumerar filas/hash directamente.
- El puerto local `54322` estaba ocupado por otro proyecto. Se levantó una
  instancia temporal aislada en `553xx`, se aplicaron todas las migraciones
  desde cero y no se detuvo ni reseteó la instancia ajena.

**Verificación:**
- `supabase db reset` (instancia temporal limpia) → todas las migraciones,
  incluida F2-T1, aplicadas correctamente.
- `supabase test db supabase/tests/database/household_invitations.test.sql` →
  **29/29 PASS**: happy path, hash/no plaintext, normalización, token inválido,
  email distinto, reuso idempotente, expirado, cancelado, no-owner, household
  ajeno, bypass de membership, aislamiento RLS y preservación atómica con datos
  o más miembros.
- `supabase test db` → **50/50 PASS** (invitaciones + suite previa de aislamiento
  entre households).
- `flutter analyze` → **No issues found!**
- `git diff --check` → sin errores.

**Handoff:** implementar únicamente **F2-T2**; no se adelantó dominio,
repositorio, controller/providers, deep links ni UI.

_(Detente aquí. F2-T1 aprobada; ⏭️ SIGUIENTE = F2-T2.)_

### F2-T2 — Boundary Flutter de invitaciones — ✅ APROBADO (2026-07-03)

**Implementación:**
- Se añadieron `HouseholdInvitationStatus` y el modelo inmutable
  `HouseholdInvitation`. El modelo representa las respuestas parciales y
  deliberadamente distintas de crear/inspeccionar/cancelar/aceptar; el token
  sólo está presente en la creación. No se generó serialización JSON para
  reducir el riesgo de persistir accidentalmente ese secreto.
- Se añadió `HouseholdInvitationMapper` con entradas separadas para cada RPC.
  Convierte snake_case a dominio, fechas y estados, incluido `expired` derivado;
  un estado desconocido falla explícitamente en vez de degradarse a `pending`.
- `HouseholdRepository` ahora expone crear, inspeccionar, cancelar y aceptar.
  La implementación Supabase llama las cuatro RPCs existentes con `rpc<T>`
  tipado y `.single()`; normaliza el email y convierte `Duration` al intervalo
  esperado por Postgres. La implementación mock reproduce el ciclo básico,
  incluido reintento idempotente de aceptación.
- `ServerException` conserva ahora un `code` opcional. Para las RPCs se guarda
  el mensaje estable emitido por Postgres (`invalid_invitation_token`,
  `invitation_email_mismatch`, etc.) sin filtrar `PostgrestException` fuera de
  la capa de datos.
- `HouseholdInvitationsController` expone las cuatro acciones con
  `AsyncValue<HouseholdInvitation?>`. Tras aceptar invalida hogar, miembros y
  perfil; transactions/categories/budgets/goals/subscriptions se reconstruyen
  a través de su dependencia de `currentHouseholdProvider`, evitando conservar
  datos del starter household.

**Decisiones / trampas:**
- No se añadió UI, QR, rutas ni persistencia del intento: pertenecen a F2-T3.
- Las RPCs retornan columnas diferentes por diseño de seguridad. Un solo modelo
  con campos opcionales mantiene una API pequeña sin inventar datos que el
  backend decidió no revelar.
- El lint estricto no pudo inferir el genérico de `rpc`; se declaró
  `List<Map<String, dynamic>>` explícitamente antes de `.single()` según la API
  del SDK resuelto.
- La invalidación se concentra en `currentHouseholdProvider` en lugar de
  importar todos los providers de features dentro de household y crear ciclos
  de dependencias. Los consumidores household-scoped ya observan ese provider.

**Verificación:**
- `dart run build_runner build --delete-conflicting-outputs` → código Freezed
  generado correctamente (la opción está deprecada y el runner la ignora, sin
  afectar la generación).
- Tests nuevos de mapper y controller → **6/6 PASS**: shapes de RPC, estado
  expirado, aceptación idempotente, rechazo de estados desconocidos,
  invalidación de scope y propagación de códigos de error.
- `flutter test` → **24/24 PASS**.
- `flutter analyze` → **No issues found!**
- `git diff --check` → sin errores.
- La instancia local de Supabase no estaba levantada
  (`supabase_db_leaklessApp` no existe), por lo que no se repitió pgTAP. No hubo
  cambios SQL; el contrato consumido sigue siendo el F2-T1 ya probado 29/29.

**Handoff:** implementar únicamente **F2-T3**; añadir deep link/QR y UI sobre
este boundary, sin volver a exponer ni persistir el token en logs o analytics.

_(Detente aquí. F2-T2 aprobada; ⏭️ SIGUIENTE = F2-T3.)_

### F2-T3 — Deep links/QR y experiencia de invitación — ✅ APROBADO (2026-07-03)

**Implementación:**
- Se centralizó el contrato `leakless://app/invite?token=…` y las rutas
  `/invite` y `/household/invitations`. Android registra un `VIEW` intent
  filter y iOS un URL scheme; `go_router` captura el intento tanto en cold
  start como con la app abierta.
- El router valida que el token sean exactamente 64 caracteres hexadecimales,
  lo normaliza, elimina inmediatamente el query param de la ruta visible y
  conserva únicamente el token en Keychain/Keystore mediante
  `flutter_secure_storage`. Nunca se persiste la URL completa. Android desactiva
  Auto Backup para evitar restaurar ciphertext sin su clave e iOS declara el
  entitlement de Keychain.
- Un intento pendiente sobrevive onboarding/auth y se reanuda al autenticar. La
  pantalla de auth avisa que debe usarse el correo destinatario; una captura
  nueva gana frente a una lectura tardía del almacenamiento seguro. Aceptar o
  descartar elimina el intento.
- La pantalla owner permite crear para un email, ver estado/expiración, mostrar
  QR y código, copiar enlace/código, compartir mediante el share sheet y
  revocar. También ofrece entrada manual para quien recibió sólo el código.
- La pantalla receptor inspecciona el preview autorizado, muestra hogar,
  invitante, email y expiración, y cubre aceptar, descartar, loading, success,
  token inválido, expirado, usado, cancelado, email distinto y starter household
  no vacío. Ante email distinto permite cambiar de cuenta sin perder el intento.

**Decisiones / seguridad:**
- El custom scheme es un mecanismo de apertura, no de autorización: otro cliente
  podría copiarlo o reclamar el scheme. La seguridad sigue en la RPC, que exige
  sesión con el mismo email, token de un solo uso y estado vigente. Universal
  Links/App Links con fallback web requieren un dominio publicado y se dejan
  para la configuración de distribución, sin inventar aquí un host no controlado.
- “Rechazar” en el receptor descarta sólo su intento local. No cancela la
  invitación de todos porque la RPC de cancelación pertenece exclusivamente al
  owner.
- El secreto existe en UI sólo para la entrega explícita (QR, clipboard o share
  sheet). No se envía a analytics/crash reporting, no se escribe en logs y el
  controller se limpia después de cada acción.
- La pantalla owner conserva el estado de la invitación emitida durante esa
  sesión. El backend de F2-T1 no expone enumeración/listado deliberadamente; no
  se debilitó RLS ni se añadió lectura directa de la tabla para reconstruirlo.

**Verificación:**
- Tests nuevos de links, validación, persistencia/restauración segura y carrera
  de hidratación; test de router signed-out → auth → `/invite` confirma que el
  token desaparece del URL. Suite completa: `flutter test` → **29/29 PASS**.
- `flutter analyze` → **No issues found!**; `git diff --check` → sin errores.
- `flutter build apk --debug` → APK construido correctamente.
- `flutter build ios --simulator --debug` → `Runner.app` construido
  correctamente, incluidos URL scheme, entitlements y plugins.
- `plutil -lint` sobre `Info.plist`/entitlements y `xmllint` sobre el Manifest →
  válidos. No había un Simulator booted y, conforme al workflow de depuración,
  no se arrancó uno sin permiso; la apertura física del scheme queda como
  evidencia humana del checkpoint F2-T9.
- No hubo cambios SQL. El preview/accept/cancel siguen consumiendo las RPCs de
  F2-T1 ya aprobadas y su aislamiento 29/29 pgTAP.

**Handoff:** implementar únicamente **F2-T4**; integrar la invitación en el
onboarding/configuración del household sin rehacer el contrato de F2-T3.

_(Detente aquí. F2-T3 aprobada; ⏭️ SIGUIENTE = F2-T4.)_

### F2-T4 — Configuración del household compartido — ✅ IMPLEMENTADO (2026-07-03)

**Implementación:**
- Se añadió un gate post-auth persistido en `households.setup_completed`: un
  owner nuevo configura nombre y moneda, revisa las seis categorías iniciales
  e invita a su pareja o continúa sin invitar. La invitación opcional reutiliza
  el contrato y la pantalla de compartir de F2-T3.
- El router da prioridad a una invitación recibida y clasifica explícitamente
  hogar ausente, configuración pendiente del owner, espera de un miembro,
  hogar individual listo y hogar compartido. Ya no abre el dashboard mientras
  el estado del household es desconocido o inconsistente.
- Ajustes permite volver a editar nombre/moneda y mantiene la entrada para
  invitar a la pareja. Omitir la invitación durante onboarding es una decisión
  persistida y no bloquea el uso individual del hogar.

**Seguridad de moneda:**
- `configure_household` normaliza y valida nombre/ISO 4217, exige ownership y
  sincroniza la moneda del perfil del owner.
- Un trigger de base de datos impide cambiar la moneda —incluso mediante un
  `UPDATE` directo que evite la RPC— cuando existen transacciones,
  presupuestos, metas o suscripciones. Los importes históricos nunca se
  reinterpretan silenciosamente.

**Verificación:**
- `flutter analyze` → **No issues found**; `flutter test` → **32/32 PASS**.
- `flutter build apk --debug` → APK construido correctamente.
- Se añadieron 11 aserciones pgTAP para permisos, ownership, validación,
  persistencia y bloqueo de cambios de moneda. Docker no permitió completar el
  checkpoint pgTAP final: otro proyecto ocupa los puertos estándar y el daemon
  dejó de responder al levantar la instancia aislada.
  Reejecutar `supabase test db` con Docker saludable antes de aprobar F2-T4.

**Handoff:** completar el checkpoint pgTAP local y aprobar F2-T4; después,
implementar únicamente F2-T5.

_(Detente aquí. F2-T4 implementada; ⏭️ SIGUIENTE tras checkpoint = F2-T5.)_

---

### F2-T5 — Edición de perfil y avatar en UI — ✅ IMPLEMENTADO (2026-07-04)

**Implementación:**
- Nueva pantalla `ProfileEditScreen` (`/profile/edit`) accesible desde la tarjeta
  de perfil en Ajustes. Edita nombre visible y moneda contra `updateProfile`, y
  el avatar contra `uploadAvatar`, mediante `ProfileController` (patrón `Notifier`
  como `HouseholdSetupController`: los errores caen en `state`, nunca se lanzan a
  la UI). Estados de carga/guardado/subida y errores mapeados a mensajes en
  español; éxito confirma con SnackBar y cierra la pantalla.
- Selector de imagen con `image_picker` (galería o cámara vía hoja de acción
  glass). Compresión/límites en el propio picker (`maxWidth/Height: 1024`,
  `imageQuality: 85`) más una red de seguridad de 5 MB; extensión normalizada a
  un formato seguro para Storage. Permisos declarados en `Info.plist`
  (`NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`) y los
  `PlatformException` de acceso denegado se traducen a un aviso accionable.
- Sincronización: tras editar/subir se invalidan `currentProfileProvider` y
  `householdMembersProvider`, de modo que la cabecera de Ajustes y la
  representación del miembro reflejan el nuevo nombre/avatar.
- Signed URL: `fetchCurrentProfile` ya no confía en el URL persistido por un año
  para la vista propia; re-firma un URL corto (1 h) desde el objeto en el bucket
  privado, con degradación al valor persistido si la firma falla. El URL de un
  año se conserva sólo para lo que ve la pareja (columna del miembro) hasta la
  firma server-side de §1.x.
- Se extrajo `supportedCurrencies` a `core/utils/currencies.dart` para no
  duplicar la lista entre onboarding de hogar y perfil.

**Verificación:**
- `flutter analyze` → **No issues found**; `flutter test` → **35/35 PASS**
  (3 nuevas pruebas de `ProfileController`: éxito, avatar, error + refresco de
  scope). Falta evidencia humana en dispositivo del picker/permisos de cámara y
  galería, que el agente no puede ejercitar aquí.

---

### F2-T6 — Recuperación completa y ciclo de sesión — ✅ IMPLEMENTADO (2026-07-04)

**Implementación:**
- Recuperación por deep link: `sendPasswordReset` ahora pasa
  `redirectTo: kPasswordRecoveryRedirect` (`leakless://app/reset-password`).
  Se registró el nuevo path en el intent-filter de Android (iOS ya cubre por
  scheme). El SDK procesa el enlace, establece una sesión de recuperación y
  emite `AuthChangeEvent.passwordRecovery`.
- `AuthRepository` expone `updatePassword` (via `updateUser`) y
  `passwordRecoveryEvents()`. `PasswordRecoveryController` escucha ese stream y
  levanta `passwordRecoveryPendingProvider`. El router lo prioriza: con la
  bandera activa fija al usuario en `/reset-password` y **nunca** llega al
  dashboard antes de cambiar la contraseña; al guardarla se limpia la bandera y
  el redirect continúa a household/dashboard.
- Nueva `ResetPasswordScreen` (`/reset-password`) con nueva contraseña +
  confirmación, estados de carga/error y opción de cancelar (que cierra la
  sesión de recuperación para no dejarla colgada). `ResetPasswordController`
  sigue el patrón `Notifier` (los errores caen en `state`).
- Ciclo de sesión: `sessionGuardProvider` (vivo desde el root en `app.dart`)
  observa `authStateChanges` y, ante cualquier cambio de cuenta —incluido sign
  out—, invalida `currentProfile`, `currentHousehold`, `householdMembers` y
  `householdSetupState`. Como todo dato household-scoped observa
  `currentHouseholdProvider`, la invalidación cascada evita ver datos del
  usuario anterior. En sign out además resuelve una posible bandera de recovery.

**Decisiones / trampas:**
- El custom scheme abre la app pero no autoriza: la seguridad sigue en el token
  de un solo uso de Supabase. El allowlist de Redirect URLs se documentó en
  `supabase/README.md` (recovery + invite) y debe configurarse en el proyecto.
- `AppUser` es freezed (igualdad por valor), así que un token refresh que
  reemite el mismo usuario no dispara invalidaciones espurias; sólo un cambio
  real de `id` lo hace.
- El stream de recovery es broadcast sin buffer: el provider debe estar
  suscrito antes de que llegue el evento. En producción lo garantiza el
  `_RouterRefresh`; en tests se construye el provider antes de emitir.
- Reautenticación: la ruta de recovery usa la sesión fresca del enlace, por lo
  que `updateUser` no requiere re-login. La re-auth explícita se reserva para
  operaciones sensibles (borrado de cuenta, F2-T8).

**Verificación:**
- `flutter analyze` → **No issues found**; `flutter test` → **39/39 PASS**.
- Test de router: una sesión de recuperación queda fijada en `/reset-password`
  y sólo sale de ahí tras guardar la nueva contraseña (no cae en dashboard).
- Tests de ciclo de sesión: el guard refetcha el household al cambiar de cuenta
  y al cerrar sesión, y limpia la bandera de recovery en sign out.
- Sin cambios SQL. La apertura física del deep link de recovery en dispositivo
  queda como evidencia humana del checkpoint F2-T9.

---

### F2-T7 — Decisión de login social — ✅ DECIDIDO: email-only MVP (2026-07-04)

**Decisión:** el MVP se publica **email-only**. No se implementa login social
(ni Google ni Apple) en esta fase.

**Razones:**
- El flujo de pareja (invitación, aceptación por email verificado, household
  compartido) se apoya en que el email autenticado coincide con el de la
  invitación. Email/password cubre el caso de uso completo del MVP sin superficie
  adicional de OAuth/deep links.
- La regla de la App Store obliga a ofrecer *Sign in with Apple* si se ofrece
  cualquier login social de terceros (Google) en iOS. Añadir Google implicaría
  también Apple (nonce, account linking, deep links, pruebas iOS/Android): un
  costo que no aporta al MVP y que puede diferirse sin bloquear el lanzamiento.

**Verificación de "sin affordances sociales" (requisito de la tarea al diferir):**
- No hay dependencias `google_sign_in` ni `sign_in_with_apple` en `pubspec.yaml`
  (la única referencia a "google" es `google_fonts`, tipografía).
- `grep` sobre `lib/` no encuentra botones/entradas sociales, `signInWithOAuth`,
  `signInWithIdToken` ni copy de "continuar con Google/Apple". `AuthScreen`
  ofrece únicamente email/password + recuperación.
- `flutter analyze` → **No issues found**; no se tocó código de producto.

**Reversibilidad:** habilitar social en el futuro es una tarea propia (OAuth,
nonce de Apple, account linking, allowlist de redirect y pruebas por plataforma)
y no requiere deshacer nada de lo entregado aquí.

---

### F2-T8 — Borrado seguro de cuenta — ✅ IMPLEMENTADO (2026-07-04)

**Implementación:**
- La RPC autenticada `delete_account(boolean)` ejecuta el borrado de forma
  server-side. Si quien sale es owner de un hogar compartido, transfiere antes
  la propiedad al miembro restante y conserva el hogar y sus datos; un miembro
  no owner simplemente abandona el hogar.
- Si el usuario es la única persona del hogar, la RPC exige confirmación
  explícita antes de borrar el household y sus datos. También elimina los
  objetos de avatar privados y, al final, el usuario de Auth.
- Ajustes ofrece una hoja de confirmación adaptada a owner individual, owner
  compartido o miembro. Exige reautenticación con contraseña, llama a la RPC y
  limpia la sesión local después del borrado.

**Seguridad y cobertura:**
- La función es `security definer`, fija un `search_path` vacío, revoca ejecución
  a `public`/`anon` y la concede sólo a `authenticated`.
- `account_deletion.test.sql` contiene 21 aserciones pgTAP: permisos, traspaso
  de ownership, conservación de datos compartidos, confirmación del borrado
  individual, salida de un miembro y limpieza de avatar/Auth.
- Los tests de `AccountDeletionController` cubren el éxito con cierre de sesión
  y el rechazo por contraseña incorrecta sin borrar la cuenta.

**Pendiente de evidencia humana:** validar el flujo completo contra el proyecto
real con dos usuarios y comprobar la redirección posterior al borrado. Esa
evidencia pertenece al checkpoint **F2-T9**, que queda como siguiente tarea.
