# Dashboard de insights (Fase 7)

Nueva pestaña **"Dashboard"** con estadísticas del mes, calculadas 100% en el
cliente a partir de los datos que ya existían (transacciones, presupuestos,
categorías). No agrega tablas ni RPCs nuevas.

## Qué cambió

- **Colisión de nombres evitada a propósito**: la feature `lib/src/features/dashboard/`
  (tab "Inicio", ruta `/dashboard`) sigue siendo el Home de siempre — no se
  tocó. La pantalla nueva vive en `lib/src/features/insights/`, ruta
  `/insights`, con label de navbar **"Dashboard"**. Pendiente como mejora
  futura: renombrar la feature vieja a `home` para que el código deje de
  contradecir la UI.
- **Navbar**: el slot 2 (antes Presupuestos) ahora es Dashboard
  (`app_shell.dart`, ícono `CupertinoIcons.chart_pie_fill`). Las 5 tabs:
  Inicio, Historial, Dashboard, Metas, Ajustes.
- **Presupuestos no se eliminó**: `/budgets` salió del `StatefulShellRoute` y
  pasó a ruta top-level (`parentNavigatorKey: _rootNavigatorKey` en
  `app_router.dart`), mismo patrón que `/settings/categories`. El path se
  conservó igual a propósito para que `notification_router.dart` (tipos
  `budget_alert`/`limit_reached`) siga abriendo la pantalla correcta desde un
  push. Puntos de entrada: fila "Presupuestos" en Ajustes
  (`settings_screen.dart`) y la card de alertas del Home
  (`summary_cards.dart`, `context.go` → `context.push` para dejar una ruta
  atrás al volver).

## Rutas

| Ruta | Tipo | Notas |
|---|---|---|
| `/insights` | tab (slot 2 del shell) | pantalla nueva de este documento |
| `/budgets` | top-level, `parentNavigatorKey` | sin cambios de funcionalidad, solo de ubicación en el árbol de rutas |

## Widgets nuevos

`lib/src/features/insights/`:

- `domain/month_insights.dart` — read-model puro `MonthInsights.from(...)`;
  toda la agregación vive aquí, cero cálculos en widgets.
- `application/insights_providers.dart` — `monthInsightsProvider`
  (`Provider<AsyncValue<MonthInsights>>`), combina los streams existentes de
  transacciones/presupuestos/categorías/hogar.
- `presentation/insights_screen.dart` + `presentation/widgets/`:
  - `month_summary_card.dart` — total gastado vs presupuesto, estado del mes.
  - `spending_pace_card.dart` — ritmo real vs esperado.
  - `category_breakdown_card.dart` — gasto por categoría.
  - `runaway_category_card.dart` — categorías ≥15% sobre su promedio 3m.
  - `trend_card.dart` — comparativo mes anterior / promedio 3m + mini-tendencia.
  - `projection_card.dart` — proyección de cierre de mes.
  - `daily_spend_card.dart` — barras por día del mes.
  - `weekday_pattern_card.dart` — día de la semana más/menos caro.
  - `category_last_activity_card.dart` — última transacción por categoría.
  - `uncategorized_card.dart` — gastos sin categoría del mes + CTA
    "Categorizar ahora" (navega al historial con el filtro `uncategorized`
    activo).
  - `recommendations_card.dart` — nudges accionables (siempre muestra al
    menos uno; refuerzo positivo cuando todo va bien).

Compartido: `lib/src/shared/widgets/mini_bar_chart.dart` (barras/sparkline
sin dependencias de charting).

## Filtro "sin categorizar" en el historial

`TransactionFilter` (`transactions_providers.dart`) ganó un campo
`uncategorizedOnly`, mutuamente excluyente con `categoryId`. La UI tiene un
chip nuevo en `transactions_screen.dart`
(`controller.toggleUncategorized`), y el CTA de `uncategorized_card.dart`
llama a `controller.showUncategorizedOnly()` (siempre lo activa, a
diferencia del toggle del chip) antes de `context.go(AppRoutes.transactions)`.

## Métricas calculadas

Ver los tunables y el detalle de cada cálculo en los docstrings de
`month_insights.dart`. Resumen:

- Resumen del mes, ritmo vs presupuesto, proyección de cierre (confiable con
  ≥5 días transcurridos y ≥3 gastos).
- Desglose por categoría con tendencia vs promedio de 3 meses.
- Categorías "fuera de control" (piso de $20 + ≥2 meses de histórico + ≥15%
  sobre su promedio).
- Comparativo histórico (mes anterior, promedio 3m, serie de 4 meses).
- Gasto diario y patrón por día de la semana.
- Sin categorizar (conteo + monto).
- Recomendaciones ordenadas por impacto.

## Semántica multimoneda

Home ya no presenta el flujo mensual como si fuera patrimonio. `FinancialOverview`
deriva el saldo actual por cuenta en su moneda nativa y lo valora en la moneda de
reporte con la última tasa disponible. `DashboardSummary.balance` se conserva
como alias compatible del flujo mensual; las APIs nuevas usan `netFlow` y
`totalBalance` para que ambas magnitudes no puedan confundirse.

Insights suma `reportingAmount`, nunca los minor units originales de monedas
distintas. `IncomeInsights` añade ingresos por fuente y exposición por moneda;
las transferencias quedan excluidas de ingresos, gastos y ahorro.

## Gaps de backend (no bloquean el v1)

1. **Presupuesto total mensual explícito**: no existe una columna así; hoy se
   deriva como Σ de los presupuestos por categoría del mes. Propuesta futura:
   `households.monthly_budget numeric null`.
2. **Meta de gasto mensual**: `Goal` modela ahorro acumulado, no un objetivo
   de gasto. La card "Ritmo vs meta" usa el presupuesto total derivado; sin
   presupuestos, muestra el CTA "Crear presupuesto" en vez de datos. Propuesta
   futura: `households.monthly_target`.
3. **Escala**: el cálculo es 100% client-side sobre el histórico completo del
   hogar. Aceptable para el volumen de una pareja/hogar; con años de datos
   convendría una RPC de Supabase tipo
   `monthly_category_totals(household_id, months)` que agregue en el servidor.

## Mejoras futuras (no en este alcance)

- Selector de mes en la pantalla de insights (v1 fija el mes actual).
- `households.monthly_budget` / `households.monthly_target` (ver gaps arriba).
- RPC de agregados server-side para households con mucho histórico.
- Renombrar la feature `dashboard` (Home) a `home` para eliminar la colisión
  de nombres con esta pantalla.

## Checklist de pruebas manuales pre-producción

- [ ] Las 5 tabs del navbar navegan a sus pantallas correctas; el tab 2 dice
      "Dashboard" y abre `/insights`.
- [ ] Desde Ajustes, "Presupuestos" abre `/budgets` con botón de volver
      (back) que regresa a Ajustes.
- [ ] Un push de alerta de presupuesto (`budget_alert`/`limit_reached`) sigue
      abriendo `/budgets` correctamente (no rompió el cambio de ruta a
      top-level).
- [ ] La card de alertas del Home navega a `/budgets` dejando el Home atrás
      en la pila (botón de volver funciona).
- [ ] Insights: estado de carga, error con reintento, y vacío (sin
      transacciones nunca registradas) se ven bien.
- [ ] Con transacciones pero sin presupuestos: la card de resumen y la de
      desglose por categoría muestran el CTA "Crear presupuesto" en vez de
      barras de progreso vacías.
- [ ] Con menos de 5 días transcurridos o menos de 3 gastos en el mes: la
      card de proyección muestra el mensaje de "necesitamos más datos" en vez
      de un número.
- [ ] Sin mes anterior con datos: la card de comparativo histórico muestra la
      nota suave en vez de un porcentaje de cambio.
- [ ] Con al menos una categoría ≥15% sobre su promedio de 3 meses: aparece
      la card de "fuera de control" con el badge correcto.
- [ ] Con gastos sin categoría este mes: aparece la card correspondiente; el
      botón "Categorizar ahora" abre el historial con el chip "Sin
      categorizar" ya activo y solo esas transacciones visibles.
- [ ] La card de recomendaciones siempre muestra al menos una fila; con todo
      en orden, el mensaje es de refuerzo positivo (nunca culpabilizador).
- [ ] Los tres idiomas (es/en/pt) muestran todas las cards, fechas y
      pluralizaciones (por ejemplo "1 gasto" vs "N gastos") sin claves
      faltantes ni texto en el idioma equivocado.
- [ ] Modo mock (sin `.env`): toda la pantalla de insights funciona igual con
      los datos de `demo_data.dart`.
