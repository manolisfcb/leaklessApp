# Leakless icon assets

Este ZIP contiene los iconos generados a partir del diseño seleccionado de Leakless.

## Incluye

- `master/`: icono principal 1024x1024 y 512x512, más versión transparente.
- `all_png_sizes/`: PNGs en tamaños comunes: 16, 20, 24, 29, 32, 36, 40, 48, 50, 57, 58, 60, 64, 72, 76, 80, 87, 96, 100, 114, 120, 128, 144, 152, 167, 180, 192, 256, 384, 512 y 1024 px.
- `ios/AppIcon.appiconset/`: set listo para Xcode con `Contents.json` y `1024x1024`.
- `android/res/`: launcher icons para Android en mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi, más adaptive icon básico.
- `android/play_store/`: iconos 512x512 y 1024x1024.
- `web/`: favicons, `favicon.ico`, Apple touch icon, Android Chrome icons y `site.webmanifest`.
- `flutter/`: icono 1024 y ejemplo para `flutter_launcher_icons`.
- `variants_1024_preview/`: variantes visuales a 1024 px para comparar.

## Flutter rápido

Copia los archivos de `flutter/` a `assets/icons/`, usa el YAML de ejemplo y corre:

```bash
dart run flutter_launcher_icons
```

Para iOS, los PNG están sin transparencia. Para web/PWA, incluí `.ico`, PNGs y manifest.
