# leakless — Checklist de camino a Producción (trabajo tarea por tarea)

> Documento de trabajo + **handoff entre agentes**. Se avanza **una tarea a la
> vez**: se implementa, se verifica, se marca **APROBADO**, y **se detiene** para
> que otro agente (o el humano) continúe con la siguiente.
>
> Roadmap completo y contexto de negocio: [PRODUCCION_Y_MONETIZACION.md](PRODUCCION_Y_MONETIZACION.md).
> Última actualización: 2026-07-01.

---

## 📌 Instrucciones para el próximo agente (leer primero)

1. **Lee este archivo completo** antes de tocar nada. El estado real vive aquí,
   no en tu memoria.
2. **Haz SOLO la siguiente tarea sin marcar** (la que dice `⏭️ SIGUIENTE`). No
   adelantes trabajo de tareas posteriores.
3. **Sigue el patrón de `transactions`** (es el ejemplo real y completo):
   - `abstract interface class XRepository` + `MockXRepository` (ya existe) +
     `SupabaseXRepository` en el **mismo** archivo `*_repository.dart`.
   - Un **mapper** dedicado `x_mapper.dart` que traduce snake_case ⟷ dominio
     (los `.name` de los enums coinciden con los valores de texto del DB).
   - Errores envueltos en `ServerException(...)` (ver `core/errors/app_exception.dart`).
   - **Cablea el provider** para elegir Supabase vs mock con
     `ref.watch(supabaseEnabledProvider)` (ver `household_providers.dart` /
     `transactions_providers.dart` como referencia).
4. **Verifica**: corre `flutter analyze` y déjalo **sin issues**. Si la tarea
   toca modelos freezed nuevos, corre `dart run build_runner build --delete-conflicting-outputs`.
5. **Actualiza este archivo**: marca tu tarea como `✅ APROBADO` con fecha, mueve
   el `⏭️ SIGUIENTE` a la tarea que sigue, y **añade una entrada en el
   "Registro de razonamiento"** explicando qué hiciste y por qué, más cualquier
   trampa que encontraste.
6. **Detente**. No continúes con la siguiente tarea. Deja el handoff listo.

---

## Estado del entorno (verificado 2026-07-01)

- Supabase **linkeado**: `project-ref = zgngezrlalklqnlwscgd`.
- Las **2 migraciones ya están aplicadas en remoto** (`supabase migration list`:
  local y remoto coinciden). Esquema + RLS + `is_household_member()` + trigger
  `handle_new_user` (auto-provisión) están vivos en la DB.
- `.env` tiene `SUPABASE_URL` + `SUPABASE_ANON_KEY` ⟹ `supabaseReady = true` en
  [bootstrap.dart](../lib/src/bootstrap.dart) ⟹ la app usa el backend real.
- Gate de calidad del repo: `flutter analyze` **sin issues** + `flutter test`.

### Cómo fluye el `householdId` (clave del diseño)

`currentHouseholdProvider` → `householdRepositoryProvider` → produce el
`householdId` real con el que **todas** las demás features filtran sus queries
(RLS lo exige). Por eso el repo de `household` es el eslabón 0.

---

## Fase 1 — Backend real (P0 🔴). Se ataca en orden de dependencia.

- [x] **T1 — `SupabaseHouseholdRepository` + cableado del provider.** ✅ **APROBADO (2026-07-01)**
- [x] **T2 — `SupabaseCategoriesRepository` + cableado.** ✅ **APROBADO (2026-07-01)**
  - Archivo: [categories_repository.dart](../lib/src/features/transactions/data/categories_repository.dart)
    (ojo: vive dentro de `transactions/data/`). Tabla `categories`
    (`id, household_id, name, icon_name, color_hex, is_default, created_at`).
    Cablea su provider por `supabaseEnabledProvider`. Va primero porque
    `transactions` y `budgets` referencian `category_id`.
- [x] **T3 — `SupabaseBudgetsRepository` + cableado.** ✅ **APROBADO (2026-07-01)**
  - `budgets_repository.dart`. Nota: `budgets.spent` está denormalizado; por
    ahora léelo tal cual del row. El recálculo server-side (trigger/vista) es
    una tarea aparte de la Fase 1.2 del roadmap.
- [x] **T4 — `SupabaseGoalsRepository` (+ `contribute()`) + cableado.** ✅ **APROBADO (2026-07-01)**
  - Incluye aportar a una meta (RPC o `update` transaccional). Revisa cómo la
    UI llama a `contribute` hoy.
- [x] **T5 — `SupabaseSubscriptionsRepository` + cableado.** ✅ **APROBADO (2026-07-01)**
- [x] **T6 — `SupabaseProfileRepository` + cableado.** ✅ **APROBADO (2026-07-01)**
  - Leer/editar `profiles`; subir avatar al bucket `avatars` (Storage). 
- [ ] **T7 — 🔴 Checkpoint HUMANO: smoke test e2e en simulador.** ⏭️ **SIGUIENTE**
  - Registrar un usuario nuevo → verificar en el dashboard de Supabase que el
    trigger creó `profiles` + `households` + `household_members` + 6
    `categories` → registrar un gasto rápido → confirmar que aterriza en la
    tabla real y **sincroniza** entre dos sesiones. Requiere correr la app; un
    agente no puede cerrarla solo. Deja evidencia aquí.
- [ ] **T8 — Test de aislamiento RLS (2 households distintos).**
  - Verificar que un usuario del household A **no** puede leer datos del B
    (pgTAP o script con 2 usuarios). Riesgo clave de una app financiera.

> Al terminar la Fase 1, el siguiente bloque del roadmap es **Fase 2 (auth +
> invitar pareja)**. No empezar antes de cerrar la Fase 1.

---

## Registro de razonamiento (handoff trail)

Cada agente **añade** su entrada abajo (no borra las previas).

### T1 — `SupabaseHouseholdRepository` — ✅ APROBADO (2026-07-01)

**Por qué esta tarea primero:** aunque `transactions` y `auth` ya tenían
implementación Supabase, `householdRepositoryProvider` estaba **clavado en
`MockHouseholdRepository`**, devolviendo siempre `DemoData.household` (id falso
`'demo-household'`). Como `currentHouseholdProvider` alimenta el `householdId`
de todas las demás queries, incluso el repo real de `transactions` consultaba un
household inexistente ⟹ RLS no matcheaba ⟹ historial vacío / inserts huérfanos.
Era el bloqueante 0 de todo el backend real.

**Qué hice:**
- Nuevo mapper [household_mapper.dart](../lib/src/features/household/data/household_mapper.dart)
  con `HouseholdMapper.fromRow` y `HouseholdMemberMapper.fromRow` (snake_case →
  dominio; `MemberRole.name` coincide con `'owner'`/`'member'` del CHECK).
- `SupabaseHouseholdRepository` en [household_repository.dart](../lib/src/features/household/data/household_repository.dart):
  - `fetchCurrentHousehold()` resuelve el household del usuario logueado leyendo
    `profiles.household_id` (que el trigger `handle_new_user` enlaza al
    registrarse) y luego trae la fila de `households`. Usa `maybeSingle()` para
    tolerar "usuario aún sin household".
  - `fetchMembers(householdId)` lee `household_members` ordenado por
    `created_at`. Errores → `ServerException`.
- Cableé [household_providers.dart](../lib/src/features/household/application/household_providers.dart)
  para elegir Supabase vs mock con `supabaseEnabledProvider`.

**Decisiones / trampas:**
- Elegí `profiles.household_id` como fuente del household "activo" (en vez de
  `select * from households` a secas) para ser explícito sobre *cuál* household
  cuando en el futuro un usuario pertenezca a más de uno. RLS igual acota
  `households` a los del miembro, así que ambas vías funcionan hoy.
- La política `profiles self access` es `id = auth.uid()`, así que leer el
  propio `profiles` no necesita nada extra.
- **No** reusé `Household.fromJson` porque el JSON de freezed espera camelCase
  (`ownerId`, `createdAt`) y el DB devuelve snake_case; por eso el mapper
  dedicado, igual que `TransactionMapper`.

**Verificación:** `flutter analyze` → **No issues found** (proyecto completo).
No corrí la app (eso es el checkpoint T7). No se tocaron modelos freezed, así que
no hizo falta `build_runner`.

**Pendiente que dejo anotado para T7:** al probar en simulador, confirmar que
`fetchCurrentHousehold` devuelve el household real justo después del signup (el
trigger corre en el `after insert` de `auth.users`; debería estar listo cuando
la sesión existe, pero validarlo).

---

### T2 — `SupabaseCategoriesRepository` — ✅ APROBADO (2026-07-01)

**Por qué esta tarea ahora:** las `categories` son el eslabón siguiente al
household porque `transactions` y `budgets` referencian `category_id`. Con T1
resolviendo el `householdId` real, ya se puede leer las categorías reales que el
trigger `handle_new_user` sembró (las 6 por defecto) en vez del `DemoData`.

**Qué hice:**
- Nuevo mapper [category_mapper.dart](../lib/src/features/transactions/data/category_mapper.dart)
  con `CategoryMapper.fromRow` (snake_case → dominio: `icon_name`, `color_hex`,
  `is_default`, `household_id`, `created_at`), igual que `TransactionMapper`.
- `SupabaseCategoriesRepository` en [categories_repository.dart](../lib/src/features/transactions/data/categories_repository.dart):
  `select` sobre `categories` filtrado por `household_id`, ordenado por
  `created_at`. Errores → `ServerException`.
- Cablée [categories_providers.dart](../lib/src/features/transactions/application/categories_providers.dart)
  para elegir Supabase vs mock con `supabaseEnabledProvider`, y `categoriesProvider`
  ahora resuelve el `householdId` vía `currentHouseholdProvider.future` (mismo
  patrón que `transactionsStreamProvider`) antes de pedir las categorías.

**Decisiones / trampas:**
- **Cambié la firma del interface** de `fetchCategories()` a
  `fetchCategories(String householdId)`. La RLS (`is_household_member`) ya acota
  `categories` al household del usuario, pero filtrar explícito es defensa en
  profundidad y sigue el patrón de `transactions`/`household` (threading del
  `householdId`). El mock ignora el parámetro. Ningún consumidor se rompe: todos
  usan los providers derivados (`categoriesProvider`/`categoriesByIdProvider`)
  que leen `.asData?.value`, así que tolera el nuevo `await` del household.
- **No** reusé `TransactionCategory.fromJson`: el freezed espera camelCase
  (`iconName`, `colorHex`, `isDefault`) y el DB devuelve snake_case; de ahí el
  mapper dedicado (misma razón que anotó T1).
- `icon_name` es `not null default 'cart'` en la migración, pero dejé un
  `?? 'cart'` defensivo en el mapper, igual que el `?? 'USD'` de T1.

**Verificación:** `flutter analyze` → **No issues found!** No se tocaron modelos
freezed, así que no hizo falta `build_runner`. No corrí la app (eso es T7).

**Pendiente que dejo anotado para T7:** al probar en simulador, confirmar que
`categoriesProvider` devuelve las 6 categorías reales del household recién creado
(y ya no las de `DemoData`) tras el signup.

---

### T3 — `SupabaseBudgetsRepository` — ✅ APROBADO (2026-07-01)

**Por qué esta tarea ahora:** con T1 (household) y T2 (categories) resueltos, ya
existe el `householdId` real y los `category_id` reales que `budgets` referencia
(FK a `categories`). Es el siguiente eslabón de dependencia antes de `goals`.

**Qué hice:**
- Nuevo mapper [budget_mapper.dart](../lib/src/features/budgets/data/budget_mapper.dart)
  con `BudgetMapper.fromRow` (snake_case → dominio), igual que `TransactionMapper`:
  `amount_limit`/`spent` son `numeric` en unidades mayores ⟹ `Money.fromMajor(...)`
  con la `currency` del row; `period_start` (tipo `date`) → `DateTime.parse`.
- `SupabaseBudgetsRepository` en [budgets_repository.dart](../lib/src/features/budgets/data/budgets_repository.dart):
  `select` sobre `budgets` filtrado por `household_id`, ordenado por
  `period_start` descendente (período actual primero). Errores → `ServerException`.
- Cablée [budgets_providers.dart](../lib/src/features/budgets/application/budgets_providers.dart)
  para elegir Supabase vs mock con `supabaseEnabledProvider`. `budgetsProvider` ya
  resolvía el `householdId` vía `currentHouseholdProvider.future`, así que no hubo
  que tocarlo.

**Decisiones / trampas:**
- **`spent` se lee tal cual** de la columna denormalizada (como indica la nota de
  T3). El recálculo server-side (trigger/vista) es la Fase 1.2 del roadmap, no
  esta tarea.
- El interface `fetchForHousehold(String householdId)` ya recibía el `householdId`
  (a diferencia de `categories`, cuya firma tuve—T2—que cambiar), así que el mock
  no se tocó y ningún consumidor se rompe.
- La tabla trae **`amount_limit`** (no `limit`, que es palabra reservada en SQL) y
  su propia columna **`currency`**; el mapper usa ambas para construir el `Money`
  del `limit` y del `spent`. `spent` tiene default 0 en la DB, pero dejé un
  `?? 0` defensivo igual que los fallbacks de T1/T2.
- **No** reusé `Budget.fromJson`: el freezed espera camelCase + un `Money` anidado
  (`{minorUnits, currency}`), mientras el DB devuelve snake_case con importes en
  unidades mayores; de ahí el mapper dedicado (misma razón que T1/T2).

**Verificación:** `flutter analyze` → **No issues found!** No se tocaron modelos
freezed, así que no hizo falta `build_runner`. No corrí la app (eso es T7).

**Pendiente que dejo anotado para T7:** al probar en simulador, confirmar que
`budgetsProvider` devuelve los budgets reales del household (y ya no los de
`DemoData`) y que `Budget.ratio`/`status` pintan bien con los importes reales.

---

### T4 — `SupabaseGoalsRepository` (+ `contribute()`) — ✅ APROBADO (2026-07-01)

**Por qué esta tarea ahora:** con T1 (household) resolviendo el `householdId`
real, `goals` es el siguiente eslabón de dependencia. A diferencia de `budgets`,
`goals` **escribe** (aporte express), así que hubo que resolver también cómo
persistir la contribución contra el backend.

**Qué hice:**
- Nuevo mapper [goal_mapper.dart](../lib/src/features/goals/data/goal_mapper.dart)
  con `GoalMapper.fromRow` (snake_case → dominio): `target_amount`/`saved_amount`
  son `numeric` en unidades mayores ⟹ `Money.fromMajor(...)` con la `currency`
  del row; `deadline` (tipo `date`) → `DateTime.tryParse`; `status` vía
  `_enumByName` (los `GoalStatus.name` — `active`/`completed`/`paused`/`archived`
  — coinciden con el CHECK del DB), igual que `TransactionMapper`.
- `SupabaseGoalsRepository` en [goals_repository.dart](../lib/src/features/goals/data/goals_repository.dart):
  - `watchForHousehold` vía `.stream(primaryKey: ['id']).eq('household_id', …)`
    y `fetchForHousehold` vía `select`, ambos ordenados por `created_at` y
    filtrados por `household_id` (mismo patrón que `transactions`). Errores →
    `ServerException`.
  - `contribute()`: **read-modify-write** de `saved_amount` — lee la fila, suma
    `amountMinorUnits`, y marca `status = 'completed'` si alcanza el `target`. La
    UI (`goals_screen.dart`) llama `contribute(goalId, amountMinorUnits)` donde
    los minor units ya vienen en la `currency` de la meta, así que sumo minor
    units exactos y persisto `newSaved.major` (la columna es `numeric(14,2)`).
- Cablée [goals_providers.dart](../lib/src/features/goals/application/goals_providers.dart)
  para elegir Supabase vs mock con `supabaseEnabledProvider`. `goalsStreamProvider`
  ya resolvía el `householdId` vía `currentHouseholdProvider.future`, así que no
  hubo que tocarlo.

**Decisiones / trampas:**
- **Elegí read-modify-write en Dart en vez de una RPC.** El checklist permite
  ambas ("RPC o `update` transaccional"), pero un `update` de PostgREST setea
  valores literales, no expresiones (`saved_amount = saved_amount + x` no se puede
  vía el builder). La RPC atómica exigiría una **3ª migración** que un agente no
  puede aplicar/verificar en remoto (el estado dice "las 2 migraciones ya están
  aplicadas"), e introduciría un fallo en runtime hasta hacer `db push`. El
  read-modify-write funciona **de inmediato** contra el esquema ya desplegado,
  igual que T1–T3, que se mantuvieron 100% en Dart sin migraciones nuevas.
- **Tradeoff honesto:** el read-modify-write **no es atómico** — dos aportes
  simultáneos de la pareja pueden perder una actualización (lost update). Lo dejé
  documentado en el docstring de `contribute` y lo marco como hardening propio de
  **§1.2 del roadmap** (cálculo confiable server-side), análogo a `budgets.spent`.
  Recomiendo una RPC `contribute_to_goal(goal_id, amount)` con
  `saved_amount = saved_amount + amount` cuando se aborde esa fase.
- **No seteo `updated_at`** en el `update`: `goals` tiene el trigger
  `set_updated_at before update` (migración `20260630000001`, línea 195), igual
  que `transactions` que tampoco lo setea.
- Tras `contribute`, **no emito manualmente** (a diferencia del mock): el stream
  realtime refleja el `update`, igual que `transactions.add` confía en realtime.
  Esto depende de que la **replicación de `goals` esté activa** (roadmap §1.4,
  pendiente) para que el otro miembro vea el progreso al instante.
- **No** reusé `Goal.fromJson`: el freezed espera camelCase + `Money` anidado
  (`{minorUnits, currency}`), y el DB devuelve snake_case con importes mayores; de
  ahí el mapper dedicado (misma razón que T1/T2/T3).

**Verificación:** `flutter analyze` → **No issues found!** No se tocaron modelos
freezed, así que no hizo falta `build_runner`. No corrí la app (eso es T7).

**Pendiente que dejo anotado para T7:** al probar en simulador, confirmar que
(1) `goalsStreamProvider` devuelve las metas reales del household, y (2) un aporte
express incrementa `saved_amount` en la tabla real y **sincroniza** el progreso
entre dos sesiones (valida de paso que la replicación de `goals` esté activa).

---

### T5 — `SupabaseSubscriptionsRepository` — ✅ APROBADO (2026-07-01)

**Por qué esta tarea ahora:** es el último repo de datos "de sólo lectura" de la
Fase 1 antes del perfil (T6, que ya implica escritura + Storage). Con el
`householdId` real de T1, sólo faltaba leer las `subscriptions` reales en vez de
`DemoData`. La tabla ya existe en la migración `20260630000001`
(`id, household_id, name, amount, currency, status, next_charge_at, category_id,
created_at, updated_at`).

**Qué hice:**
- Nuevo mapper [subscription_mapper.dart](../lib/src/features/subscriptions/data/subscription_mapper.dart)
  con `SubscriptionMapper.fromRow` (snake_case → dominio): `amount` (`numeric`
  mayor) → `Money.fromMajor(...)` con la `currency` del row; `status` vía
  `_enumByName` (los `SubscriptionStatus.name` — `active`/`trial`/`paused`/
  `canceled` — coinciden con el CHECK del DB); `next_charge_at` (`timestamptz`)
  → `DateTime.tryParse`. Mismo patrón que `TransactionMapper`/`GoalMapper`.
- `SupabaseSubscriptionsRepository` en [subscriptions_repository.dart](../lib/src/features/subscriptions/data/subscriptions_repository.dart):
  read-only `fetchForHousehold` vía `select` filtrado por `household_id`,
  ordenado por `next_charge_at` ascendente. Errores → `ServerException`. Es un
  repo de sólo lectura, así que **sin stream** (igual que `budgets`; la interface
  ya sólo declara `fetchForHousehold`).
- Cablée [subscriptions_providers.dart](../lib/src/features/subscriptions/application/subscriptions_providers.dart)
  para elegir Supabase vs mock con `supabaseEnabledProvider`. `subscriptionsProvider`
  ya resolvía el `householdId` vía `currentHouseholdProvider.future`, así que no
  hubo que tocarlo.

**Decisiones / trampas:**
- **Orden por `next_charge_at` ascendente** (próximo cobro primero): es el orden
  natural para suscripciones (recordatorios de cobro, feature premium del
  roadmap), análogo a `transactions` por `occurred_at`. `next_charge_at` es
  nullable ⟹ los nulos van al final (default de Postgres en orden ascendente),
  comportamiento correcto (suscripciones sin próximo cobro conocido al fondo).
  Consideré `created_at` (más neutro), pero no hay un consumidor que fije el
  orden — `subscriptionsProvider` sólo alimenta el `DashboardSummary` (suma
  montos), así que elegí el orden más útil de cara al futuro listado.
- **Sin `stream`**: la interface `SubscriptionsRepository` sólo expone
  `fetchForHousehold` (no hay escritura ni realtime en esta feature todavía), así
  que seguí el patrón de `budgets` (read-only) en vez del de `transactions`
  (stream + add). Si más adelante se añade la detección automática de
  suscripciones (roadmap §4), habrá que sumar realtime aquí.
- **No** reusé `SubscriptionItem.fromJson`: el freezed espera camelCase + `Money`
  anidado (`{minorUnits, currency}`), y el DB devuelve snake_case con importe en
  unidades mayores; de ahí el mapper dedicado (misma razón que T1–T4).
- No toqué el mock ni ningún consumidor: la interface no cambió, sólo se añadió
  la implementación Supabase.

**Verificación:** `flutter analyze` → **No issues found!** No se tocaron modelos
freezed, así que no hizo falta `build_runner`. No corrí la app (eso es T7).

**Pendiente que dejo anotado para T7:** al probar en simulador, confirmar que
`subscriptionsProvider` devuelve las suscripciones reales del household (y ya no
las de `DemoData`); nótese que la migración **no siembra** suscripciones por
defecto, así que la lista real puede venir vacía hasta que se inserten filas.

---

### T6 — `SupabaseProfileRepository` — ✅ APROBADO (2026-07-01)

**Por qué esta tarea ahora:** es el último repo de la Fase 1 antes del checkpoint
humano (T7). A diferencia de T1–T5 (lecturas), `profiles` **se edita** y además
implica **Storage** (avatar en el bucket `avatars`), así que hubo que resolver
lectura + escritura + subida de archivo. El `profiles` es per-usuario (RLS
`id = auth.uid()`), no per-household, así que no depende del `householdId`.

**Qué hice:**
- Nuevo mapper [profile_mapper.dart](../lib/src/features/profile/data/profile_mapper.dart)
  con `ProfileMapper.fromRow` (snake_case → dominio: `display_name`,
  `household_id`, `avatar_url`, `currency`, `created_at`, `updated_at`), igual que
  `TransactionMapper`.
- Extendí el interface `ProfileRepository` en [profile_repository.dart](../lib/src/features/profile/data/profile_repository.dart)
  de sólo `fetchCurrentProfile()` a **3 métodos**: `fetchCurrentProfile()`,
  `updateProfile({displayName, currency})` y
  `uploadAvatar({bytes, fileExtension})`. Los dos de escritura **devuelven el
  `UserProfile` fresco** (mismo contrato que `transactions.add`, que devuelve la
  fila insertada).
- `SupabaseProfileRepository`:
  - `fetchCurrentProfile()` lee la fila `profiles` del `auth.currentUser` con
    `maybeSingle()` (tolera "aún sin fila"), como `household.fetchCurrentHousehold`.
  - `updateProfile()` hace `update(...).eq('id', userId).select().single()`,
    seteando sólo los campos no nulos vía **null-aware map entries**
    (`'display_name': ?displayName`). Si no hay nada que actualizar, re-lee y
    devuelve el perfil actual (evita un `update` vacío que PostgREST rechaza).
  - `uploadAvatar()` sube los bytes a `avatars/<user-id>/avatar.<ext>` con
    `upsert: true`, genera un **signed URL** y lo persiste en `avatar_url`; luego
    devuelve el perfil actualizado.
  - Todo envuelto en `ServerException`; helpers `_requireUserId` (→
    `AuthFailureException` si no hay sesión) y `_requireProfile` (→
    `NotFoundException`).
- Actualicé el `MockProfileRepository` para implementar los 3 métodos con estado
  **mutable** en memoria (antes era `const`), igual que `MockTransactions`/
  `MockGoals` mutan y reflejan el cambio, para que la UI de ajustes vea las
  ediciones antes de tener backend.
- Cablée [profile_providers.dart](../lib/src/features/profile/application/profile_providers.dart)
  para elegir Supabase vs mock con `supabaseEnabledProvider` (antes estaba clavado
  en `const MockProfileRepository()`).

**Decisiones / trampas:**
- **Bucket privado ⟹ guardo un signed URL en `avatar_url`.** El bucket `avatars`
  es privado (`public = false` en la migración), así que `getPublicUrl` no sirve.
  Guardo un signed URL de **1 año** que se refresca en cada subida; así el
  `ProfileBubble` (que usa `NetworkImage(avatarUrl)`) funciona **de inmediato**
  sin infra nueva. **Tradeoff honesto:** el URL caduca. El hardening correcto es
  resolver un signed URL fresco **en cada lectura** (o hacer el bucket público);
  lo dejo anotado como follow-up §1.x, análogo al `budgets.spent`/`goals` de
  T3/T4. No lo hice ahora porque `ProfileMapper.fromRow` es síncrono y resolver el
  URL en lectura exigiría await/branching extra sin un consumidor que lo pida aún.
- **Path `<user-id>/avatar.<ext>`** para cumplir la RLS `avatars owner manage`
  (`owner = auth.uid()`, convención `avatars/<user-id>/…` de la migración).
  `upsert: true` reemplaza el avatar anterior; el token nuevo del signed URL
  invalida el cache del `NetworkImage` de paso.
- **No seteo `updated_at`** en los `update`: `profiles` tiene el trigger
  `set_updated_at before update` (migración `20260630000001`, arrays de la línea
  195), igual que `transactions`/`goals` que tampoco lo setean.
- **Null-aware map entries** (`'display_name': ?displayName`) en vez de
  `if (x != null) 'display_name': x`: el lint `use_null_aware_elements` de
  `flutter_lints` (SDK Dart 3.10) marca el `if` como issue; la sintaxis nueva lo
  evita y deja `flutter analyze` limpio.
- **No** reusé `UserProfile.fromJson`: el freezed espera camelCase
  (`displayName`, `avatarUrl`, `householdId`) y el DB devuelve snake_case; de ahí
  el mapper dedicado (misma razón que T1–T5).
- El interface cambió (2 métodos nuevos), pero **ningún consumidor se rompe**: el
  `settings_screen.dart` sólo lee `currentProfileProvider` (`.asData?.value`); la
  UI de edición/subida de avatar aún no existe (es trabajo futuro de Fase 2).

**Verificación:** `flutter analyze` → **No issues found!** No se tocaron modelos
freezed, así que no hizo falta `build_runner`. No corrí la app (eso es T7).

**Pendiente que dejo anotado para T7:** al probar en simulador, confirmar que
(1) `currentProfileProvider` devuelve el perfil real del usuario tras el signup,
(2) editar `display_name`/`currency` persiste en la tabla real, y (3) subir un
avatar aterriza en `avatars/<user-id>/…` y el `ProfileBubble` lo pinta vía el
signed URL. Ojo con el tradeoff del signed URL que caduca (ver arriba).

---

### T7 — 🔴 Checkpoint HUMANO — ⏳ PENDIENTE (bloqueado por diseño: requiere humano)

**Por qué NO lo marco APROBADO:** T7 es un checkpoint humano por definición.
Verificar el trigger en el **dashboard de Supabase**, registrar un usuario en la
app **corriendo**, y confirmar que un gasto **sincroniza entre dos sesiones** son
acciones interactivas que un agente no puede ejecutar ni observar de forma
fiable. Marcarlo `✅ APROBADO` sería afirmar una verificación que no hice. Lo dejo
en `⏳ PENDIENTE` y hago en su lugar el **pre-flight estático** que sí puedo, para
des-riesgar la prueba humana.

**Pre-flight estático que sí verifiqué (2026-07-01):**
- **`flutter analyze` → No issues found** (proyecto completo). Incluye el trabajo
  de T6 aún sin commitear (profile repo/mapper/providers).
- **Los 6 repos de la Fase 1 están cableados a Supabase**: los 8 providers
  relevantes leen `supabaseEnabledProvider` (household, categories, budgets,
  goals, subscriptions, profile, transactions, auth). No queda ninguno clavado en
  mock.
- **El trigger `handle_new_user`** (migración `20260630000002_auto_provision_user.sql`)
  crea **exactamente** lo que T7 espera confirmar: 1 `households` ('Nuestra casa'),
  1 `profiles` (enlazado al household), 1 `household_members` (`role='owner'`), y
  **6 `categories`** por defecto (Supermercado, Restaurantes, Transporte, Ocio,
  Suscripciones, Ahorro, todas `is_default=true`). El conteo "6 categorías" del
  checklist es correcto.

**Runbook para el humano (ejecutar la prueba e2e):**
1. `flutter run` en el simulador (con `.env` cargado ⟹ `supabaseReady=true`).
2. **Registrar un usuario nuevo** desde la pantalla de auth.
3. En el **dashboard de Supabase** (`project-ref = zgngezrlalklqnlwscgd` →
   Table editor), confirmar que aparecieron: fila en `profiles`, fila en
   `households`, fila en `household_members` (owner), y **6 filas** en `categories`
   para ese `household_id`.
4. En la app, **registrar un gasto** rápido y confirmar en `transactions` (misma
   fila en la tabla real).
5. **Sincronización:** abrir una **segunda sesión** (otro simulador/dispositivo
   con el mismo usuario, o el segundo miembro del household) y confirmar que el
   gasto/objetivo aparece **en tiempo real** sin refrescar. Esto valida de paso
   que la **replicación realtime** de `transactions`/`goals` esté activa (ver
   pendientes que anotaron T4 y T6 sobre realtime).
6. Si todo pasa: marcar T7 como `✅ APROBADO` con fecha, mover `⏭️ SIGUIENTE` a
   **T8**, y anotar aquí la evidencia (capturas del dashboard / IDs de filas).

**Trampas heredadas a vigilar durante la prueba** (de los registros previos):
- **T4 (goals):** el aporte express es **read-modify-write no atómico**; dos
  aportes simultáneos pueden perder una actualización. Y la sync del progreso
  depende de que la replicación de `goals` esté activa.
- **T6 (profile):** `avatar_url` guarda un **signed URL que caduca** (1 año); el
  bucket `avatars` es privado. Al probar el avatar, tenerlo presente.
- **Estado git:** el trabajo de T6 sigue **sin commitear** (working tree con
  `profile_*` + este checklist). Commitear antes o después de T7 según prefiera el
  humano.

_(Detente aquí: no puedo cerrar un checkpoint humano. Handoff listo para la persona.)_
