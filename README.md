# leakless

**leakless** es una app móvil (Flutter) para parejas que quieren controlar sus
gastos, **detectar micro-fugas de dinero** (gastos hormiga), sincronizar el gasto
en tiempo real, manejar presupuestos, metas de ahorro y recibir alertas
inteligentes — con una estética **Liquid Glass** (vidrio translúcido estilo iOS).

> Estado: **setup inicial de producción**. Arquitectura, sistema visual, rutas,
> pantallas navegables y capa de servicios listos. Los datos son _mock_ hasta
> conectar Supabase (ver [Próximos pasos](#próximos-pasos)).

---

## Stack

| Área | Paquete |
| --- | --- |
| Navegación | `go_router` |
| Estado | `flutter_riverpod` |
| Modelos inmutables | `freezed` + `json_serializable` |
| Backend | `supabase_flutter` (auth, DB, realtime, storage) |
| Infra push/crash/analytics | `firebase_core`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics` |
| Monetización | `purchases_flutter` (RevenueCat) |
| Config | `flutter_dotenv` (`.env`) |
| i18n / dinero | `intl` |
| Tipografía | `google_fonts` (Outfit) |
| Local | `shared_preferences` |

Dart 3 / Flutter estable. Lints estrictos (`analysis_options.yaml`).

---

## Puesta en marcha

```bash
# 1. Dependencias
flutter pub get

# 2. Variables de entorno (no se suben secretos reales)
cp .env.example .env
#   edita .env con tus claves de Supabase y RevenueCat

# 3. Generar código (freezed / json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 4. Correr
flutter run

# 5. Tests
flutter test

# 6. Análisis estático
flutter analyze
```

La app **corre sin backend**: si `.env` no tiene claves de Supabase, usa
repositorios _mock_ (ver `lib/src/core/dev/demo_data.dart`) y es 100% navegable.

> ℹ️ El código generado (`*.freezed.dart`, `*.g.dart`) está en `.gitignore`;
> ejecuta `build_runner` tras clonar. Si el bootstrap de `build_runner` falla con
> _"'dart compile' does not support build hooks"_, es por los `dependency_overrides`
> de `path_provider_*` que ya están en `pubspec.yaml` para evitarlo.

---

## Arquitectura

**Feature-first + Clean Architecture** con Riverpod, adoptada para Leakless. Cada
feature separa sus capas; lo transversal vive en
`core/`; los widgets reutilizables en `shared/`; el dominio es Dart puro.

```
lib/
├── main.dart                 # entrypoint → bootstrap()
└── src/
    ├── app.dart              # MaterialApp.router (tema + i18n + router)
    ├── bootstrap.dart        # init de servicios + ProviderContainer + runApp
    ├── core/                 # infraestructura transversal
    │   ├── config/           # Env + AppConfig (.env, flags has*)
    │   ├── theme/            # design tokens (colores, tipografía, radios…) + AppTheme
    │   ├── router/           # go_router, rutas, shell con bottom-nav
    │   ├── supabase/         # init + SupabaseClient provider
    │   ├── firebase/         # init guardado (opcional hasta flutterfire)
    │   ├── notifications/    # NotificationService + FCM + permisos + router
    │   ├── analytics/        # AnalyticsService (Firebase)
    │   ├── monitoring/       # CrashReporter (Crashlytics)
    │   ├── purchases/        # RevenueCat → Entitlement
    │   ├── bank/             # (FUTURO) parsers SMS/notif + detector automático
    │   ├── errors/           # AppException / AppFailure
    │   ├── utils/            # MoneyFormatter, iconos de categoría
    │   └── dev/              # demo_data (mock)
    ├── domain/               # Dart puro: sin Flutter/Supabase/Firebase
    │   ├── enums/            # TransactionType, Priority, ResponsibleType, …
    │   └── models/           # freezed: Money, Transaction, Budget, Goal, …
    ├── shared/widgets/       # GlassCard, GlassButton, LiquidTubeIndicator, …
    └── features/
        ├── onboarding/  auth/  dashboard/  quick_entry/  transactions/
        ├── budgets/  goals/  subscriptions/  household/  profile/
        └── <feature>/
            ├── data/         # repositorios (interface + mock + Supabase) + mappers
            ├── application/  # providers + controllers (Riverpod)
            ├── domain/       # modelos/agregados propios de la feature
            └── presentation/ # pantallas + widgets de la feature
```

### Reglas que respeta la base

- La UI solo habla con providers/controllers/usecases — **nunca** llama directo a
  Supabase / Firebase / RevenueCat.
- El **dominio** no depende de ningún backend ni de Flutter.
- Sin colores/textos/medidas hardcodeados: todo sale de los _design tokens_.
- Widgets reutilizables en `shared/`; los específicos, dentro de su feature.
- Repositorios con interfaz + implementación _mock_ + implementación Supabase
  (patrón completo en la feature **transactions**: datasource, mapper, realtime).

### Flujo de navegación

`go_router` con redirect: **onboarding → auth → app**. La app usa un
`StatefulShellRoute` (IndexedStack) con bottom-nav de 5 pestañas
(Inicio · Historial · Presupuestos · Metas · Ajustes) y un botón central de
**Registro rápido** (hoja de vidrio).

---

## Sistema visual (Liquid Glass)

Tokens centralizados en `lib/src/core/theme/`:

- Fondo `#F0F4FA` · Texto `#1E293B`
- Ingresos/futuro `#00D09C` · Gastos `#FF5A79` · Alertas `#FFB03A` · Metas `#3082FF`
- Tarjetas de vidrio con `BackdropFilter`, bordes de refracción y sombras difusas.
- Indicadores líquidos animados (`LiquidTubeIndicator`, `LiquidProgressBar`) y el
  **hidrómetro financiero** del dashboard.

Iconografía lineal estilo iOS (`CupertinoIcons`), tipografía **Outfit** vía
`google_fonts` (sin binarios en el repo).

---

## Backend / servicios

### Supabase
Backend principal. Migraciones en [`supabase/migrations/`](supabase/) (tablas,
RLS por household, trigger de auto-provisión, bucket de avatares). Ver
[`supabase/README.md`](supabase/README.md). Configura `SUPABASE_URL` y
`SUPABASE_ANON_KEY` en `.env` y los repositorios cambian de _mock_ a Supabase
automáticamente.

### Firebase
Solo infraestructura: push (`firebase_messaging`), crash (`crashlytics`),
analytics. **Opcional** para desarrollo local — sin `flutterfire configure` la
init se salta y los servicios son _no-op_. Para activarlo:

```bash
dart pub global activate flutterfire_cli
flutterfire configure   # genera lib/firebase_options.dart (git-ignored)
```

### RevenueCat
`purchases_flutter` → `Entitlement` del dominio. Configura
`REVENUECAT_PUBLIC_KEY_IOS/ANDROID` en `.env`.

---

## Próximos pasos

1. **Supabase real:** crear proyecto, aplicar migraciones, rellenar `.env`,
   activar Realtime en `transactions`. Implementar los repositorios Supabase que
   faltan (budgets, goals, subscriptions, profile, household) siguiendo el patrón
   de `transactions`.
2. **Firebase:** `flutterfire configure` + probar push cruzada (gasto → pareja),
   idealmente vía Edge Function de Supabase.
3. **Auth completa:** validación de formularios, recuperación de contraseña,
   invitar a la pareja al household.
4. **l10n:** extraer los textos ES a `flutter_localizations` / ARB.
5. **Automatización bancaria (fase futura):** implementar `BankMessageParser` /
   `BankNotificationParser` / `AutomaticTransactionDetector` (hoy son stubs sin
   permisos sensibles).
6. **Monetización:** definir _entitlements_/paywall con RevenueCat.
7. (Opcional) Extraer el _design system_ a un package (`packages/app_ui`) al
   estilo Melos, como en Dreamly, si el proyecto crece.

---

## Pruebas

`flutter test`. La base incluye tests de: modelo `Money` y enums de dominio,
`MoneyFormatter`, un provider de Riverpod y el widget `GlassCard`.
