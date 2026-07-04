# App icon & splash source art

Drop the brand art here, then generate the platform assets.

| File | Size | Purpose |
|------|------|---------|
| `icon.png` | 1024×1024, no transparency | Main launcher icon (iOS + Android legacy) |
| `icon_foreground.png` | 1024×1024, transparent | Android 8+ adaptive foreground (safe zone ~66%) |
| `splash.png` | ~1152×1152, transparent | Centered launch-screen logo |

Then run once:

```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

This overwrites the default Flutter icon in `android/app/src/main/res/mipmap-*`
and `ios/Runner/Assets.xcassets/AppIcon.appiconset`. Config lives in
`pubspec.yaml` (`flutter_launcher_icons:` / `flutter_native_splash:`).
