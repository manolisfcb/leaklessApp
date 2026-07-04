import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/currencies.dart';
import '../../../domain/models/user_profile.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/profile_providers.dart';

/// Largest avatar we accept after the picker's own downscaling — a safety net
/// against oversized originals sneaking through. Uploads are re-encoded by the
/// picker (`imageQuality`), so this is rarely hit.
const _maxAvatarBytes = 5 * 1024 * 1024; // 5 MB.

/// Lets the signed-in user edit their display name, currency and avatar,
/// wired to [ProfileController] (`updateProfile` / `uploadAvatar`).
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _picker = ImagePicker();

  var _currency = 'USD';
  var _initializedProfileId = '';
  var _savingProfile = false;
  var _uploadingAvatar = false;
  String? _formError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _initialize(UserProfile profile) {
    if (_initializedProfileId == profile.id) return;
    _initializedProfileId = profile.id;
    _name.text = profile.displayName;
    _currency = profile.currency;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _savingProfile = true;
      _formError = null;
    });

    final saved = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(displayName: _name.text.trim(), currency: _currency);
    if (!mounted) return;

    if (saved == null) {
      final error = ref.read(profileControllerProvider).error;
      setState(() {
        _savingProfile = false;
        _formError = _profileErrorMessage(error);
      });
      return;
    }

    setState(() => _savingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado.')),
    );
    if (context.canPop()) context.pop();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    setState(() => _uploadingAvatar = true);
    try {
      // The picker downscales and re-encodes, keeping uploads small and the
      // format predictable regardless of the original.
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) {
        if (mounted) setState(() => _uploadingAvatar = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxAvatarBytes) {
        _failAvatar('La imagen es demasiado grande. Prueba con otra.');
        return;
      }

      final uploaded = await ref
          .read(profileControllerProvider.notifier)
          .uploadAvatar(bytes: bytes, fileExtension: _extensionFor(picked));
      if (!mounted) return;

      if (uploaded == null) {
        _failAvatar(
          _profileErrorMessage(ref.read(profileControllerProvider).error),
        );
        return;
      }
      setState(() => _uploadingAvatar = false);
    } on PlatformException catch (e) {
      _failAvatar(_pickerErrorMessage(e));
    } catch (_) {
      _failAvatar('No pudimos usar esa imagen. Inténtalo de nuevo.');
    }
  }

  void _failAvatar(String message) {
    if (!mounted) return;
    setState(() => _uploadingAvatar = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _chooseAvatarSource() async {
    final source = await GlassBottomSheet.show<ImageSource>(
      context,
      title: 'Cambiar avatar',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarSourceTile(
            icon: CupertinoIcons.photo,
            label: 'Elegir de la galería',
            onTap: () => sheetContext.pop(ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AvatarSourceTile(
            icon: CupertinoIcons.camera,
            label: 'Tomar una foto',
            onTap: () => sheetContext.pop(ImageSource.camera),
          ),
        ],
      ),
    );
    if (source != null) await _pickAvatar(source);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return GlassScaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(CupertinoIcons.back),
        ),
        title: const Text('Editar perfil'),
      ),
      body: switch (profileAsync) {
        AsyncLoading() => const AppLoader(message: 'Cargando tu perfil…'),
        AsyncError() => AppEmptyState(
          icon: CupertinoIcons.person_crop_circle_badge_exclam,
          title: 'No pudimos cargar tu perfil',
          message: 'Revisa tu conexión e inténtalo de nuevo.',
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(currentProfileProvider),
        ),
        AsyncData(:final value) when value == null => const AppEmptyState(
          icon: CupertinoIcons.person_crop_circle_badge_exclam,
          title: 'Sin perfil',
          message: 'Inicia sesión de nuevo para editar tu perfil.',
        ),
        AsyncData(:final value) => _buildForm(context, value!),
      },
    );
  }

  Widget _buildForm(BuildContext context, UserProfile profile) {
    _initialize(profile);
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      children: [
        Center(
          child: _AvatarEditor(
            profile: profile,
            uploading: _uploadingAvatar,
            onTap: _uploadingAvatar ? null : _chooseAvatarSource,
          ),
        ),
        AppSpacing.gapXl,
        Form(
          key: _formKey,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_savingProfile,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  maxLength: 80,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nombre visible',
                    hintText: 'Cómo te ve tu pareja',
                    prefixIcon: Icon(CupertinoIcons.person),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Escribe un nombre visible.'
                      : null,
                  onFieldSubmitted: (_) => _save(),
                ),
                AppSpacing.gapMd,
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(
                    labelText: 'Moneda',
                    prefixIcon: Icon(CupertinoIcons.money_dollar_circle),
                  ),
                  items: [
                    if (!supportedCurrencies.any((e) => e.$1 == _currency))
                      DropdownMenuItem(
                        value: _currency,
                        child: Text(_currency),
                      ),
                    for (final entry in supportedCurrencies)
                      DropdownMenuItem(
                        value: entry.$1,
                        child: Text('${entry.$1} · ${entry.$2}'),
                      ),
                  ],
                  onChanged: _savingProfile
                      ? null
                      : (value) =>
                            setState(() => _currency = value ?? _currency),
                ),
              ],
            ),
          ),
        ),
        if (_formError != null) ...[
          AppSpacing.gapLg,
          GlassCard(
            borderColor: colors.expense,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_circle,
                  color: colors.expense,
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Text(_formError!, style: AppTypography.bodyMedium),
                ),
              ],
            ),
          ),
        ],
        AppSpacing.gapXl,
        GlassButton(
          label: 'Guardar cambios',
          icon: CupertinoIcons.checkmark_alt,
          loading: _savingProfile,
          onPressed: _savingProfile ? null : _save,
        ),
      ],
    );
  }
}

/// Circular avatar with a camera badge and an upload spinner overlay.
class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.profile,
    required this.uploading,
    required this.onTap,
  });

  final UserProfile profile;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ProfileBubble(
            initials: profile.initials,
            imageUrl: profile.avatarUrl,
            size: 108,
          ),
          if (uploading)
            Container(
              height: 108,
              width: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.scrim,
              ),
              alignment: Alignment.center,
              child: const AppLoader(),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.background, width: 2),
              ),
              child: const Icon(
                CupertinoIcons.camera_fill,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarSourceTile extends StatelessWidget {
  const _AvatarSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          AppSpacing.gapMd,
          Expanded(child: Text(label, style: AppTypography.titleMedium)),
          Icon(CupertinoIcons.chevron_right, size: 16, color: colors.textTertiary),
        ],
      ),
    );
  }
}

/// Picks a Storage-friendly file extension. The picker re-encodes to JPEG when
/// `imageQuality` is set, so we default to `jpg` and only trust a known,
/// explicit extension on the source name.
String _extensionFor(XFile file) {
  final name = file.name.toLowerCase();
  final dot = name.lastIndexOf('.');
  final ext = dot == -1 ? '' : name.substring(dot + 1);
  return switch (ext) {
    'png' => 'png',
    'jpg' || 'jpeg' => 'jpg',
    'webp' => 'webp',
    _ => 'jpg',
  };
}

String _profileErrorMessage(Object? error) {
  if (error is AuthFailureException) return 'Inicia sesión para continuar.';
  final code = error is ServerException ? error.code : null;
  return switch (code) {
    'invalid_display_name' => 'Escribe un nombre válido de hasta 80 caracteres.',
    'invalid_currency' => 'Selecciona una moneda válida.',
    'authentication_required' => 'Inicia sesión para continuar.',
    _ => 'No pudimos guardar los cambios. Inténtalo de nuevo.',
  };
}

String _pickerErrorMessage(PlatformException e) => switch (e.code) {
  'photo_access_denied' =>
    'Permite el acceso a tus fotos desde Ajustes para elegir un avatar.',
  'camera_access_denied' =>
    'Permite el acceso a la cámara desde Ajustes para tomar una foto.',
  _ => 'No pudimos abrir el selector de imágenes. Inténtalo de nuevo.',
};
