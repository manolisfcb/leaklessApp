# Plan: mejoras de UX — Quick Entry, FAB y Pie Chart de categorías

Plan de trabajo para un agente. Ejecutar las tareas **en orden** (A → B → C → D), una por una,
con un commit por tarea. Cada tarea es independiente: si una se bloquea, las demás siguen siendo válidas.

Contexto de origen: feedback del usuario sobre el dashboard de insights y el flujo de registro rápido.
El desglose por categorías ya existe ([CategoryBreakdownCard](../lib/src/features/insights/presentation/widgets/category_breakdown_card.dart))
y no forma parte de este plan, salvo la mejora opcional de la Tarea D.

## Convenciones del repo (leer antes de empezar)

- **Arquitectura**: features en `lib/src/features/<feature>/{domain,application,presentation}`.
  Los widgets de presentación solo leen providers; la lógica vive en `application`/`domain`.
- **Tema**: usar siempre `context.colors` (`AppColors`), `AppTypography`, `AppSpacing`, `AppRadii`,
  `AppShadows`, `AppDurations` de `lib/src/core/theme/`. Nada de colores hardcodeados.
- **Widgets compartidos**: `lib/src/shared/widgets/` (exportados desde `widgets.dart`).
  Precedente de gráfico custom sin librería externa: [mini_bar_chart.dart](../lib/src/shared/widgets/mini_bar_chart.dart).
- **l10n**: los `.arb` viven en `lib/src/core/l10n/` (template: `app_es.arb`; también `app_en.arb` y `app_pt.arb`).
  Tras editar los `.arb`, correr `flutter gen-l10n`. En widgets se accede con `context.l10n.<clave>`.
- **Verificación por tarea**: `flutter analyze` sin issues nuevos + `flutter test` en verde +
  arrancar la app y comprobar manualmente el criterio de aceptación.

---

## Tarea A — Monto siempre visible en Quick Entry (feedback #4) ✅ HECHA

**Problema**: en [quick_entry_sheet.dart](../lib/src/features/quick_entry/presentation/quick_entry_sheet.dart)
el display del monto (`MoneyFormatter.format(_cents, ...)`, ~línea 238) es el primer hijo de un
`SingleChildScrollView`. El teclado numérico está al final del mismo scroll, así que al bajar para
teclear, el monto queda fuera de pantalla y el usuario escribe a ciegas.

**Solución**: fijar el display del monto como cabecera sticky del sheet; solo el resto del formulario hace scroll.

**Pasos**:
1. En `_QuickEntrySheetState.build`, reestructurar el widget raíz: en vez de
   `SingleChildScrollView > Column[monto, ...resto]`, devolver
   `Column(mainAxisSize: MainAxisSize.min)` con:
   - el display del monto (el `Center > Text` actual) como primer hijo fijo,
   - `AppSpacing.gapLg`,
   - `Flexible(child: SingleChildScrollView(child: Column(...resto del formulario...)))`.

   Nota: `GlassBottomSheet` ya envuelve el child en `Flexible` dentro de una `Column` con
   `mainAxisSize.min` ([glass_bottom_sheet.dart:86](../lib/src/shared/widgets/glass_bottom_sheet.dart)),
   así que esta estructura encaja sin overflow.
2. Mantener `crossAxisAlignment: CrossAxisAlignment.stretch` en la columna interna del scroll
   para que los botones sigan ocupando el ancho completo.
3. Verificar que al enfocar el campo "Nota" el teclado del sistema no rompe el layout
   (el sheet ya se eleva con `AnimatedPadding` sobre `viewInsets`; el monto fijo debe seguir visible
   o, como mínimo, no causar overflow — probar en un iPhone con pantalla pequeña o ventana baja).
4. Opcional si queda natural (no obligatorio): considerar fijar también el botón "Guardar" al pie
   (monto arriba fijo, scroll en el medio, Guardar abajo fijo). Solo hacerlo si no complica el
   manejo del teclado del sistema; si hay dudas, dejar Guardar dentro del scroll.

**Criterio de aceptación**: con el sheet abierto y el scroll en la posición del teclado numérico,
cada dígito tecleado se refleja inmediatamente en el monto sin necesidad de hacer scroll hacia arriba.

**Tests**: ajustar/añadir un widget test (en `test/features/` siguiendo el patrón existente) que
bombee `QuickEntrySheet`, haga scroll hasta el keypad, pulse dígitos y verifique que el texto del
monto es visible (`find.text(...)` + `tester.getRect` dentro del viewport) y actualizado.

---

## Tarea B — El FAB "+" no debe tapar contenido (feedback #3) ✅ HECHA

**Problema**: el FAB de registro rápido ([app_shell.dart:26](../lib/src/core/router/app_shell.dart))
usa la posición por defecto (`endFloat`) y flota por encima de las cards; al final de las listas tapa
la última card. Las listas usan un padding inferior de ~120 px que no alcanza (nav bar 64 + margen +
FAB 60 quedan por encima).

**Solución (dos partes, ambas)**:
1. **Ocultar el FAB durante el scroll hacia abajo, mostrarlo al subir o al parar.**
   - Convertir `AppShell` en `StatefulWidget` (sigue sin providers; es puro UI de shell).
   - Envolver `body: navigationShell` con un `NotificationListener<UserScrollNotification>`:
     las notificaciones de scroll de cualquier tab burbujean hasta el shell.
     - `ScrollDirection.reverse` (bajando) → ocultar FAB.
     - `ScrollDirection.forward` (subiendo) o `ScrollDirection.idle` → mostrarlo.
   - Animar la transición con `AnimatedSlide` + `AnimatedOpacity` (o `AnimatedScale`) usando
     `AppDurations.fast`; el FAB oculto no debe recibir taps (`IgnorePointer` cuando está oculto).
2. **Aumentar el padding inferior de las listas de los tabs** para que la última card libere al FAB
   y al nav bar cuando el scroll llega al fondo:
   - Buscar los `ListView`/`ScrollView` de las pantallas raíz de los 5 tabs
     (grep por `fromLTRB(` con `120` — p. ej. [insights_screen.dart:90-96](../lib/src/features/insights/presentation/insights_screen.dart)
     y el equivalente en dashboard/transactions/goals/settings).
   - Definir una constante compartida (p. ej. `AppSpacing.bottomBarClearance` en
     `lib/src/core/theme/app_spacing.dart`) con valor ~**180** y reemplazar los `120` mágicos.

**Criterio de aceptación**:
- Al hacer scroll hacia abajo en cualquier tab, el FAB desaparece y el texto de las cards se lee completo.
- Al soltar o subir, el FAB reaparece.
- Con el scroll al fondo, la última card se ve entera por encima del nav bar.

**Tests**: widget test del shell (o de un `Scaffold` reducido con la misma lógica) que emita
notificaciones de scroll y verifique visibilidad del FAB. Si montar `AppShell` completo exige mucho
mock de router, extraer la lógica de visibilidad a un widget propio (p. ej. `_HideOnScroll`) y
testear ese widget aislado.

---

## Tarea C — Pie chart de gasto por categorías en el dashboard (feedback #2) ✅ HECHA

**Problema**: no hay vista proporcional del gasto; el usuario quiere ver de un vistazo en qué
categorías gasta más/menos. Hoy solo existe la lista con barras (`CategoryBreakdownCard`).

**Decisión ya tomada**: **sin dependencia externa** (no añadir `fl_chart`). Hacer un donut con
`CustomPainter`, siguiendo el precedente de `MiniBarChart`. Antes de escribir el código del gráfico,
el agente debe invocar la skill `dataviz` para calibrar colores/legibilidad.

**Datos disponibles** (no hace falta tocar `domain` ni `application`):
- `insights.categories` → `List<CategoryInsight>` ya ordenada por gasto, con `spent` (`Money`),
  `shareOfTotal` (0–1) y `categoryId` ([month_insights.dart](../lib/src/features/insights/domain/month_insights.dart)).
- `categoriesByIdProvider` → `Map<String, TransactionCategory>` con `name`, `iconName`, `colorHex`.
- Total del mes: `insights` ya expone el total gastado (usarlo para el centro del donut).

**Pasos**:
1. **Widget compartido** `lib/src/shared/widgets/donut_chart.dart` (+ export en `widgets.dart`):
   - API propuesta: `DonutChart({required List<DonutSlice> slices, double size = 160, double strokeWidth = 22, Widget? center})`
     donde `DonutSlice` = `({double value, Color color})`.
   - `CustomPainter` que dibuja arcos con `Canvas.drawArc` (stroke, `StrokeCap.round` solo si hay
     una única slice; con varias, `StrokeCap.butt` + un pequeño gap angular entre slices, ~2°).
   - Empezar a las 12 en punto (-π/2). Sin animación en v1 (opcional: animar el sweep con
     `TweenAnimationBuilder` si sale barato).
   - `center` se superpone con un `Stack` (para "total gastado" en el centro).
2. **Colores por categoría**: crear un helper reutilizable (p. ej. `lib/src/core/utils/category_colors.dart`):
   - Si `TransactionCategory.colorHex` existe y parsea → usarlo.
   - Fallback: paleta determinística derivada del tema (lista de ~8 colores de `AppColors`
     accesibles en claro y oscuro), indexada de forma estable (p. ej. por orden de la lista de slices,
     no por hash del id, para que la leyenda y el donut siempre coincidan).
3. **Card nueva** `lib/src/features/insights/presentation/widgets/category_pie_card.dart`:
   - `GlassCard` con título (nueva clave l10n, ver paso 4), el `DonutChart` y una leyenda.
   - Agregación: mostrar como slices las **5 categorías top** y agrupar el resto en "Otros"
     (color `colors.textTertiary` o gris del tema). Si hay ≤5, mostrarlas todas y sin "Otros".
   - Leyenda: una fila por slice → punto de color + nombre localizado
     (`categoryDisplayName(category, l10n)`, y `l10n.insightsCategoryUnnamed` si la categoría no
     existe en el mapa) + `%` (`shareOfTotal * 100`, redondeado) + monto (`AmountText`).
   - Centro del donut: total gastado del mes en `AppTypography.titleLarge` + etiqueta pequeña.
   - Layout responsive: donut arriba y leyenda debajo (columna); no hace falta variante horizontal.
4. **l10n**: añadir claves a `app_es.arb` (template) y traducciones en `app_en.arb` y `app_pt.arb`:
   - `insightsPieTitle` (es: "Distribución por categoría"; en: "Spending by category"; pt: "Distribuição por categoria"),
   - `insightsPieOthers` (es: "Otros"; en: "Others"; pt: "Outros"),
   - `insightsPieCenterLabel` (es: "gastado"; en: "spent"; pt: "gasto") — o reutilizar una clave existente si ya hay algo equivalente; revisar los `.arb` antes de crear claves nuevas.
   - Correr `flutter gen-l10n`.
5. **Integración** en [insights_screen.dart](../lib/src/features/insights/presentation/insights_screen.dart):
   dentro del bloque `if (insights.categories.isNotEmpty)`, insertar `CategoryPieCard` **antes** de
   `CategoryBreakdownCard` (primero la foto proporcional, luego el detalle con límites).
6. **Edge cases a cubrir**:
   - 1 sola categoría → círculo completo, sin gaps raros.
   - `colorHex` nulo o inválido → fallback de paleta, sin crash.
   - Slices con `shareOfTotal` diminuto (<1%) → quedan dentro de "Otros" por el top-5; si una slice
     visible redondea a 0%, mostrar "<1%".
   - Modo claro y oscuro → contraste suficiente del donut y la leyenda (validar con la skill dataviz).

**Criterio de aceptación**: en el tab Dashboard, con gastos categorizados en el mes, aparece una card
con un donut cuyas proporciones coinciden con los % de la lista de desglose, leyenda legible en ambos
temas y total del mes en el centro.

**Tests**:
- Unit test de la agregación top-5 + "Otros" (extraerla como función pura para poder testearla,
  p. ej. en la propia card como `static` o en un helper).
- Widget test de `DonutChart` que verifique que renderiza sin errores con 1, 3 y 8 slices
  (en `test/widgets/`, siguiendo el patrón de los tests existentes).

---

## Tarea D (opcional, pequeña) — "Te quedan $X" por categoría en el desglose ✅ HECHA

**Contexto**: `CategoryBreakdownCard` ya muestra gasto, % y límite, pero no el **restante** explícito,
que es lo que el usuario quiere leer ("cuánto me queda en ocio").

**Pasos**:
1. En [category_breakdown_card.dart](../lib/src/features/insights/presentation/widgets/category_breakdown_card.dart),
   `_CategoryRow`: cuando `insight.limit != null`, sustituir el texto actual del límite (línea ~126)
   por el restante: `limit - spent`.
   - Si queda ≥ 0: nueva clave l10n `insightsCategoryRemaining` (es: "Quedan {amount}";
     en: "{amount} left"; pt: "Restam {amount}") con placeholder `amount` (String ya formateado con `.format()`).
   - Si está pasado: `insightsCategoryOverBy` (es: "Excedido por {amount}"; en: "Over by {amount}";
     pt: "Excedido em {amount}"), en color `colors.expense`.
2. Añadir las claves en los tres `.arb` + `flutter gen-l10n`.
3. Comprobar que `Money` soporta la resta (revisar `lib/src/domain`); si no hay operador, restar
   `minorUnits` y reconstruir con el mismo helper que usa `month_insights.dart`.

**Criterio de aceptación**: cada categoría con presupuesto muestra "Quedan $X" (o "Excedido por $X"
en rojo) bajo su barra, en los 3 idiomas.

---

## Checklist final (después de la última tarea)

- [ ] `flutter analyze` limpio.
- [ ] `flutter test` completo en verde.
- [ ] Probar en la app real: registro rápido (monto visible), scroll en los 5 tabs (FAB se oculta,
      última card legible), dashboard con datos categorizados (donut + desglose coherentes), cambiar
      idioma a EN y PT y revisar las cadenas nuevas, y probar modo claro y oscuro.
- [ ] Un commit por tarea, mensajes estilo repo (`feat(quick-entry): ...`, `fix(shell): ...`,
      `feat(insights): ...`).
