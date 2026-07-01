# leakless — Camino a Producción y Monetización

> Documento vivo. Estado base: **setup inicial completo** (arquitectura, sistema
> visual Liquid Glass, 8 pantallas navegables, servicios cableados pero en modo
> _mock/no-op_). Este documento detalla **qué falta para prod** y **cómo
> monetizar**. Última actualización: 2026-07-01.

Leyenda de esfuerzo: 🟢 bajo (≤2d) · 🟡 medio (3–8d) · 🔴 alto (>8d).
Prioridad: **P0** bloqueante de lanzamiento · **P1** importante v1 · **P2** post-launch.

---

## 0. Resumen ejecutivo

Lo que **ya funciona** hoy:

- App compila, `flutter analyze` limpio, tests pasan, `flutter build bundle` OK.
- Arquitectura feature-first + Clean + Riverpod, sistema de diseño con tokens.
- Navegación completa (onboarding → auth → shell de 5 tabs + registro rápido).
- Capa de datos con patrón **interface + mock + Supabase** (el ejemplo real y
  completo es `transactions`: datasource + mapper + realtime).
- Migraciones SQL con RLS y auto-provisión de usuario.
- Servicios de Supabase / Firebase / RevenueCat **cableados y guardados**
  (funcionan en no-op hasta configurar `.env` / `flutterfire`).

Lo que **falta** (resumen): conectar el backend real en todas las features,
completar auth + household compartido, notificaciones cruzadas reales, la lógica
"inteligente" (burn-rate, fugas hormiga, límites), pulido de UX/estados,
seguridad/privacidad/legal, CI/CD, y publicación en stores. Detalle abajo.

**Ruta corta sugerida a un MVP monetizable:** Fase 1 (backend real) → Fase 2
(auth + pareja) → Fase 3 (notif cruzadas) → Fase 6 (paywall) → Fase 8
(hardening) → Fase 9 (stores). Estimado agregado: **~6–10 semanas** de un dev
senior para un v1 sólido de pago.

---

## 1. Backend real (Supabase) — **P0** 🔴

Hoy sólo `transactions` tiene implementación Supabase; el resto usa mocks de
`lib/src/core/dev/demo_data.dart`.

### 1.1 Implementar repositorios Supabase que faltan
Seguir el patrón de `SupabaseTransactionsRepository` (interface + mapper +
realtime + manejo de errores → `AppException`). Pendientes:

- [ ] `budgets` → `MockBudgetsRepository` ⟶ `SupabaseBudgetsRepository`
      (`lib/src/features/budgets/data/budgets_repository.dart`).
- [ ] `goals` → incluye `contribute()` (RPC o `update` transaccional).
- [ ] `subscriptions`.
- [ ] `profile` → leer/editar `profiles`, subir avatar a Storage.
- [ ] `household` → household + `household_members`, invitaciones.
- [ ] `categories`.
- [ ] Cambiar cada `*RepositoryProvider` para elegir Supabase vs mock según
      `supabaseEnabledProvider` (como ya hace `transactionsRepositoryProvider`).

### 1.2 Lógica de servidor (Postgres functions / Edge Functions)
Cosas que **no deben** calcularse solo en el cliente:

- [ ] **`budgets.spent` real**: hoy está denormalizado. Recalcular server-side
      (trigger sobre `transactions` o vista materializada por
      `household_id + category_id + período`). 🟡
- [ ] **Cálculo del "hidrómetro" / tasa de ahorro** confiable (evita
      manipulación y divergencia entre miembros). Puede ser una vista SQL. 🟡
- [ ] **Alertas inteligentes** (ver Fase 4). 🔴
- [ ] Idempotencia al insertar transacciones (evitar duplicados por reintentos).

### 1.3 Datos & migraciones
- [ ] Semillas de categorías por defecto (ya en `20260630000002`), revisar.
- [ ] Índices adicionales según queries reales; `explain analyze` de las top.
- [ ] Estrategia de migraciones versionadas + `supabase db diff` en CI.
- [ ] Backups automáticos y política de retención (plan de Supabase).

### 1.4 Realtime
- [ ] Activar replication en `transactions`, `budgets`, `goals`,
      `notification_events`.
- [ ] Probar consistencia entre los 2 miembros (el "libro contable común").
- [ ] Manejo de reconexión / estado offline (ver Fase 5).

**Riesgo clave:** verificar que **RLS** realmente aísla households (test con 2
usuarios de distintos households). Escribir tests de políticas (pgTAP o script).

---

## 2. Autenticación y Household compartido — **P0** 🔴

`SupabaseAuthRepository` ya existe; falta el flujo de producto.

- [ ] Validación de formularios (email/contraseña), errores claros por campo.
- [ ] Recuperación de contraseña (magic link / OTP).
- [ ] Login social (Apple obligatorio en iOS si hay social; Google opcional). 🟡
- [ ] **Invitar a la pareja al household** (código/deep link/QR) — es el core del
      producto. Modelo: crear invitación → aceptar → `household_members`. 🔴
- [ ] Onboarding de household: nombrar hogar, moneda, invitar pareja, categorías.
- [ ] Editar perfil + subir avatar (Storage bucket `avatars` ya creado).
- [ ] Cerrar sesión limpio (ya cableado) + borrar cuenta (requisito de stores).
- [ ] Manejo de "usuario sin household" y "esperando a que acepte la pareja".
- [ ] Refresh de sesión / expiración de token / re-auth.

---

## 3. Notificaciones cruzadas (el diferenciador) — **P0/P1** 🔴

El comentario en `firebase_messaging_service.dart` ya deja claro que el push
"gasto → pareja" se genera **server-side**.

- [ ] **Edge Function** que, al insertar una transacción, envíe push (FCM) al
      otro miembro con payload enriquecido
      (`type=transaction_created`, monto, categoría, actor). El
      `NotificationRouter` ya mapea `type → ruta`.
- [ ] Guardar `fcm_token` por dispositivo/usuario (tabla o columna) + refresh.
- [ ] `flutterfire configure` (genera `firebase_options.dart`, git-ignored).
- [ ] Permisos de notificación con buen _timing_ (no al arranque;
      `NotificationPermissionHandler` ya existe).
- [ ] Notificaciones accionables (reaccionar con "sticker"/emoji) — diseño. 🟡
- [ ] Inbox in-app leyendo `notification_events` (modelo ya existe).
- [ ] Deep links / navegación al abrir push (root navigator ya preparado).
- [ ] iOS: APNs key, capabilities, entitlements; Android: canal de notif.

---

## 4. Inteligencia financiera (features "core especializadas") — **P1** 🔴

Del diseño (`flutter_app_design.md`) falta la lógica real:

- [ ] **Detección de fuga / gasto hormiga**: hoy el dashboard sólo suma
      `priority == ant`. Falta la alerta semanal ("sus compras hormiga = 3 meses
      de Netflix") y patrón de vibración.
- [ ] **Burn-rate / alarma preventiva**: "a este ritmo superan el presupuesto 6
      días antes de fin de mes". Cálculo server-side + notificación.
- [ ] **Límite crítico compartido (90%)**: pantalla de "fricción" para ambos con
      votación (¿presupuesto extra o cenamos en casa?).
- [ ] **Detección automática de suscripciones** a partir de transacciones
      recurrentes (agrupar por comercio/monto/cadencia).
- [ ] **Ajuste de emergencia** de presupuesto (mover límite entre categorías) —
      hoy el botón muestra un snackbar placeholder en `budgets_screen.dart`.
- [ ] Selector de mes ya filtra; falta histórico real por período.

---

## 5. Offline, caché y sincronización — **P1** 🟡

- [ ] Caché local (los modelos ya son `toJson`-ables; usar `shared_preferences`
      para datos ligeros o Hive/Isar/Drift para offline serio).
- [ ] Cola de escritura offline + reconciliación con realtime.
- [ ] Estados de "sin conexión" en UI + reintentos con backoff.
- [ ] Optimistic UI en registro rápido (ya casi: el mock inserta y emite).

---

## 6. Monetización técnica (RevenueCat) — **P0 para cobrar** 🟡

Ya cableado: `PurchasesService`, `entitlementProvider`, `isPremiumProvider`.
Falta el producto:

- [ ] Crear productos/ofertas/entitlements en el dashboard de RevenueCat.
- [ ] Configurar productos en **App Store Connect** y **Google Play Console**.
- [ ] Poner claves reales en `.env` (`REVENUECAT_PUBLIC_KEY_IOS/ANDROID`).
- [ ] **Paywall**: pantalla premium (usar `purchases_ui_flutter` o custom con
      el sistema Liquid Glass) + lógica de compra/restaurar.
- [ ] **Gating**: envolver features premium con `isPremiumProvider` (ver §11).
- [ ] Manejo de estados: compra, restaurar, error, ya suscrito, trial.
- [ ] Webhooks de RevenueCat → Supabase (sincronizar entitlement server-side
      para features que dependan del backend).
- [ ] Cumplir reglas de stores (precio visible, términos, restaurar compras).

---

## 7. Calidad, i18n, accesibilidad, performance — **P1** 🟡

- [ ] **i18n**: extraer strings ES (hoy en labels/enums) a
      `flutter_localizations` + ARB. `generate: true` ya está en `pubspec`.
      Añadir EN si se apunta a mercado internacional.
- [ ] **Accesibilidad**: `Semantics`, tamaños de toque ≥48dp, contraste (ojo con
      texto sobre vidrio translúcido), soporte de _text scaling_.
- [ ] **Estados**: revisar loading/empty/error en **todas** las pantallas
      (varios ya usan `AppLoader`/`AppEmptyState`).
- [ ] **Performance**: `BackdropFilter` es caro — limitar cantidad de blurs
      simultáneos, `RepaintBoundary` en tarjetas, perfilar en gama baja.
- [ ] **Animaciones** del diseño: efecto líquido con giroscopio (sensors_plus),
      haptics en acciones clave, micro-transiciones.
- [ ] Manejo de teclado/insets en `QuickEntrySheet`.

---

## 8. Testing y hardening — **P0/P1** 🟡

- [ ] Subir cobertura: controllers (auth, quick entry, goals), mappers,
      `DashboardSummary.from`, filtros.
- [ ] Tests de **RLS** (2 households aislados).
- [ ] **Golden tests** de widgets de vidrio y pantallas clave.
- [ ] **Integration tests** (flujo onboarding→registro→aparece en historial).
- [ ] Manejo global de errores → Crashlytics (ya cableado, validar en release).
- [ ] Revisar `dependency_overrides` de `path_provider_*` cuando el toolchain
      soporte build hooks (quitar el override).

---

## 9. Publicación en stores (iOS/Android) — **P0** 🟡

- [ ] Cuentas: Apple Developer ($99/año) y Google Play ($25 único).
- [ ] Bundle IDs, firma (iOS certs/profiles, Android keystore).
- [ ] Iconos, splash, capturas, textos ASO, video.
- [ ] **Privacy Nutrition Labels** (Apple) y **Data Safety** (Google).
- [ ] Política de privacidad + términos (URL pública). **Obligatorio.**
- [ ] Borrado de cuenta in-app (obligatorio en ambos stores).
- [ ] Cumplir guidelines (finanzas: extra escrutinio; nada de scraping bancario
      sin permisos/regulación — ver §12).
- [ ] TestFlight / Play Internal Testing antes de release.

---

## 10. Infra, CI/CD y observabilidad — **P1** 🟡

- [ ] **CI** (GitHub Actions): `flutter analyze` + `flutter test` + build en PR;
      `build_runner` en el pipeline.
- [ ] **CD**: fastlane / Codemagic / Shorebird para builds firmados y OTA.
- [ ] Gestión de secretos (nunca `.env` real en repo; usar secrets del CI).
- [ ] Entornos dev/staging/prod (ya hay `APP_ENV` en `.env`).
- [ ] Observabilidad: Crashlytics + Analytics con un **plan de eventos**
      (registrar_gasto, aporte_meta, alerta_vista, paywall_visto, compra…).
      `AnalyticsService` ya centraliza eventos.
- [ ] Feature flags / Remote Config (Firebase) para lanzar gradualmente.
- [ ] Force-update gate (versión mínima) — patrón conocido de DUK/Dreamly.

---

## 11. Seguridad y privacidad — **P0** 🔴

Es una app financiera: la barra es alta.

- [ ] RLS auditado + tests (ver §8).
- [ ] Secretos sólo en `.env`/CI, nunca en el repo (ya en `.gitignore`).
- [ ] Cifrado en tránsito (TLS por defecto) y en reposo (Supabase lo da).
- [ ] Minimización de datos: no pedir más de lo necesario.
- [ ] Cumplimiento (según mercado): GDPR/CCPA, consentimiento, export/borrado.
- [ ] Rate limiting / anti-abuso en Edge Functions.
- [ ] Validación server-side de todo input (no confiar en el cliente).
- [ ] Revisión de dependencias (supply chain) y `flutter pub audit`.

---

## 12. Fase futura: automatización bancaria — **P2** 🔴 (¡regulado!)

Ya hay interfaces stub sin permisos sensibles (`core/bank/`).

- [ ] **Fase 1 (Android)**: parseo de SMS/notificaciones bancarias
      (`BankMessageParser`/`BankNotificationParser`). Requiere permisos
      sensibles → **justificación estricta en Play** y riesgo de rechazo.
- [ ] **Fase 2 (Open Finance)**: Plaid (US/EU) / Belvo (LatAm) para conexión
      regulada. Implica costos por conexión, contratos y compliance fuerte.
- [ ] Privacidad reforzada, consentimiento explícito, y auditoría legal previa.

> Recomendación: lanzar el MVP **sin** automatización bancaria (registro manual
> express + notif cruzadas ya son suficiente valor) y sumar Open Finance cuando
> haya tracción e ingresos que justifiquen el compliance.

---

## 13. Definition of Done (checklist pre-lanzamiento)

- [ ] Backend real conectado en todas las features + RLS testeado.
- [ ] Auth completa + invitar pareja + borrar cuenta.
- [ ] Notificaciones cruzadas funcionando end-to-end.
- [ ] Paywall + compras + restaurar, probados en sandbox de ambos stores.
- [ ] Crashlytics/Analytics activos en release; 0 crashes en smoke test.
- [ ] i18n mínima (ES) + estados vacíos/error en todas las pantallas.
- [ ] Política de privacidad + términos publicados y linkeados.
- [ ] CI verde (analyze + test) + build firmado.
- [ ] TestFlight/Internal testing con usuarios reales (al menos 1 pareja).

---

# Monetización

El _plumbing_ (RevenueCat → `Entitlement`) ya está. Aquí el **modelo de negocio**.

## A. Modelo recomendado: Freemium + suscripción (pareja)

El valor recurrente (sync en tiempo real, alertas, metas) encaja con
**suscripción**, no compra única. Cobrar **por pareja/household**, no por
persona (ambos miembros comparten el mismo entitlement vía backend).

### Free vs Premium (propuesta concreta)

| Capacidad | Free | Premium |
| --- | --- | --- |
| Registro manual de gastos | ✅ ilimitado | ✅ |
| Sync en tiempo real en pareja | ✅ | ✅ |
| Dashboard + hidrómetro | ✅ básico | ✅ completo |
| Presupuestos | Hasta 3 categorías | Ilimitados |
| Metas de ahorro | 1 meta | Ilimitadas |
| **Alertas inteligentes** (burn-rate, fuga hormiga, límite 90%) | ❌ | ✅ |
| **Detección de suscripciones** | Ver total | Detalle + recordatorios de cobro |
| Historial | Últimos 30 días | Ilimitado + export CSV |
| Notificaciones cruzadas enriquecidas / reacciones | Básicas | ✅ |
| Automatización bancaria (fase futura) | ❌ | ✅ |

> Regla de oro: lo gratis debe **enganchar al hábito en pareja**; lo premium
> debe ser lo que **ahorra dinero de verdad** (alertas, detección de fugas y
> suscripciones), porque ahí el usuario percibe ROI directo.

### Precios sugeridos (ajustar por mercado)
- **Mensual:** ~$4.99–$6.99 / pareja.
- **Anual:** ~$39.99–$49.99 (ancla de valor, 2–3 meses gratis vs mensual).
- **Trial:** 7 días gratis (o "prueba hasta detectar tu primera fuga").
- Considerar **precio local** (LatAm vs US/EU) vía RevenueCat + StoreKit pricing.

### Colocación del paywall (paywall placement)
- Tras el onboarding, mostrando el valor ("detecta fugas") — soft.
- Al tocar una feature premium (alertas, meta #2, presupuesto #4) — contextual.
- Cuando la app **detecta una fuga real** → momento de máxima disposición a pagar
  ("recupera $X al mes con leakless Premium").

## B. Otras palancas de ingreso (post-PMF)

- **Afiliación / lead-gen ético:** al detectar suscripciones caras o duplicadas,
  sugerir alternativas más baratas o ayudar a cancelar (comisión por
  referido). Alinea incentivo (ahorrarle dinero al usuario) con ingreso.
- **Plan "familia"** (>2 miembros) como tier superior.
- **One-time unlocks** para features puntuales (menos recomendable que sub).
- **B2B2C:** licenciar a bancos/fintechs/neobancos como feature de "finanzas en
  pareja" (canal de distribución + ingreso mayorista).
- **Datos agregados y anonimizados** (benchmarks de gasto) — **sólo** con
  consentimiento explícito y anonimización real; alto riesgo reputacional, tratar
  con cuidado.
- **Contenido/coaching financiero** premium (educación) como add-on.

> Evitar publicidad: rompe la estética premium y la confianza en una app de
> dinero en pareja.

## C. Métricas de monetización a instrumentar

- Activación: % de parejas que **ambos** registran ≥1 gasto en semana 1.
- Retención D1/D7/D30 y **retención de pareja** (los dos activos).
- Conversión free→trial→pago; **trial-to-paid**.
- Churn mensual y anual; motivo de cancelación.
- ARPU/ARPPU y **LTV**; CAC por canal; payback.
- "Aha moment": primera fuga detectada → correlación con conversión.

`AnalyticsService` ya centraliza eventos; añadir: `paywall_shown`,
`trial_started`, `purchase_completed`, `leak_detected`, `alert_actioned`.

## D. Estrategia de lanzamiento de precios

1. Lanzar con **trial + anual destacado**; medir conversión real.
2. A/B de precio y de _placement_ del paywall (Remote Config / RevenueCat
   Experiments).
3. Ofertas de introducción / early adopters; subir precio cuando haya valor
   probado (alertas + detección funcionando).

---

## Anexo: mapa código → trabajo pendiente

| Área | Dónde está hoy | Qué falta |
| --- | --- | --- |
| Repos mock | `lib/src/features/*/data/*_repository.dart` | Impl Supabase (patrón `transactions`) |
| Auth | `features/auth/data/auth_repository.dart` | Flujo completo + invitar pareja |
| Push | `core/notifications/*` | Edge Function + `fcm_token` + accionables |
| Premium | `core/purchases/*`, `isPremiumProvider` | Ofertas + paywall + gating |
| Alertas | `features/dashboard/domain/dashboard_summary.dart` | Burn-rate, fuga hormiga, límite 90% |
| Banca | `core/bank/*` (stubs) | Parseo SMS / Open Finance (fase futura, regulado) |
| Firebase | `core/firebase/`, `core/monitoring/`, `core/analytics/` | `flutterfire configure` + plan de eventos |
