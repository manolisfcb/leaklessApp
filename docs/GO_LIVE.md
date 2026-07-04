# leakless — Runbook de salida a producción

Pasos que **requieren tus credenciales/cuentas** (no se pueden hacer solo en
código). El scaffolding de código ya está listo (ver "Hecho en código" abajo).

## 1. Firma de release (Android) 🔴 BLOQUEANTE

```sh
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
cp android/key.properties.example android/key.properties
# edita android/key.properties con la ruta y contraseñas del keystore
```
`build.gradle.kts` ya detecta `key.properties` y firma el release con él.
Guarda el `.jks` fuera del repo (ya está git-ignoreado). Verifica:
```sh
flutter build appbundle --release
```

## 2. Firebase (push + Crashlytics + Analytics) 🔴 BLOQUEANTE

```sh
dart pub global activate flutterfire_cli
flutterfire configure   # genera firebase_options.dart, google-services.json, GoogleService-Info.plist
```
- Los plugins Gradle se auto-aplican en cuanto exista `android/app/google-services.json`.
- iOS: en Xcode → Runner → Signing & Capabilities → **+ Push Notifications** y
  **+ Background Modes → Remote notifications** (el `UIBackgroundModes` del
  Info.plist ya está; falta el entitlement `aps-environment` que añade esa capability).
- Sube la **APNs key (.p8)** a Firebase → Cloud Messaging → Apple app config.
- Guarda `fcm_token` por usuario (tabla/columna en Supabase) + refresh.

## 3. Ícono e imagen de arranque 🔴 BLOQUEANTE (tienda rechaza el default)

Pon el arte en `assets/icon/` (ver `assets/icon/README.md`) y:
```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## 4. RevenueCat / compras 🟠

- Crear productos + entitlements en RevenueCat, App Store Connect y Play Console.
- Poner las claves reales en `.env` (`REVENUECAT_PUBLIC_KEY_IOS/ANDROID`).
- Verificar que el paywall bloquee de verdad (probar sandbox iOS + test track Android).

## 5. Compliance de tiendas 🟠

- Política de privacidad (URL pública) + etiquetas de privacidad de App Store.
- Borrado de cuenta ya implementado ✅ (requisito de ambas tiendas).
- Cambiar `APP_ENV=prod` en el `.env` de release.

## 6. Feature core (decisión de producto) 🟡

Detección de micro-fugas / burn-rate / detección de suscripciones siguen como
placeholder (`bank_*_parser.dart` devuelven null). Decidir si v1 sale sin la
feature estrella o se completa antes. Ver `docs/PRODUCCION_Y_MONETIZACION.md` Fase 3/4.

---

## Hecho en código (este pase)

- ✅ Permisos `INTERNET` + `POST_NOTIFICATIONS` en el manifest de release.
- ✅ Firma de release por `key.properties` con fallback a debug.
- ✅ Plugins Gradle de Firebase (google-services + Crashlytics), auto-aplicados
  cuando exista `google-services.json` (no rompen el build sin él).
- ✅ `UIBackgroundModes: remote-notification` en iOS Info.plist.
- ✅ `flutter_launcher_icons` + `flutter_native_splash` configurados en pubspec.
- ✅ `flutter analyze` limpio · 41 tests verdes · gradle config OK.
