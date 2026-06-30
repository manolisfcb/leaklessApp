import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// The resolved [AppConfig] for the running app.
///
/// Reads from the already-loaded `.env` (see `Env.load` in bootstrap), so it is
/// safe to read synchronously anywhere.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnv());
