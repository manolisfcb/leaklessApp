import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
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
        _formError = _profileErrorMessage(context.l10n, error);
      });
      return;
    }

    setState(() => _savingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.profileUpdated)),
    );
    if (context.canPop()) context.pop();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final l10n = context.l10n;
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
        _failAvatar(l10n.profileImageTooLarge);
        return;
      }

      final uploaded = await ref
          .read(profileControllerProvider.notifier)
          .uploadAvatar(bytes: bytes, fileExtension: _extensionFor(picked));
      if (!mounted) return;

      if (uploaded == null) {
        _failAvatar(
          _profileErrorMessage(l10n, ref.read(profileControllerProvider).error),
        );
        return;
      }
      setState(() => _uploadingAvatar = false);
    } on PlatformException catch (e) {
      _failAvatar(_pickerErrorMessage(l10n, e));
    } catch (_) {
      _failAvatar(l10n.profileAvatarFailed);
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
    final l10n = context.l10n;
    final source = await GlassBottomSheet.show<ImageSource>(
      context,
      title: l10n.profileChangeAvatarTitle,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarSourceTile(
            icon: CupertinoIcons.photo,
            label: l10n.quickEntryPickFromGallery,
            onTap: () => sheetContext.pop(ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AvatarSourceTile(
            icon: CupertinoIcons.camera,
            label: l10n.quickEntryTakePhoto,
            onTap: () => sheetContext.pop(ImageSource.camera),
          ),
        ],
      ),
    );
    if (source != null) await _pickAvatar(source);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(currentProfileProvider);

    return GlassScaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(CupertinoIcons.back),
        ),
        title: Text(l10n.profileEditTitle),
      ),
      body: switch (profileAsync) {
        AsyncLoading() => AppLoader(message: l10n.profileLoading),
        AsyncError() => AppEmptyState(
          icon: CupertinoIcons.person_crop_circle_badge_exclam,
          title: l10n.profileLoadErrorTitle,
          message: l10n.commonCheckConnection,
          actionLabel: l10n.commonRetry,
          onAction: () => ref.invalidate(currentProfileProvider),
        ),
        AsyncData(:final value) when value == null => AppEmptyState(
          icon: CupertinoIcons.person_crop_circle_badge_exclam,
          title: l10n.profileNoProfileTitle,
          message: l10n.profileNoProfileMessage,
        ),
        AsyncData(:final value) => _buildForm(context, value!),
      },
    );
  }

  Widget _buildForm(BuildContext context, UserProfile profile) {
    _initialize(profile);
    final colors = context.colors;
    final l10n = context.l10n;

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
                  decoration: InputDecoration(
                    labelText: l10n.profileNameLabel,
                    hintText: l10n.profileNameHint,
                    prefixIcon: const Icon(CupertinoIcons.person),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.profileNameRequired
                      : null,
                  onFieldSubmitted: (_) => _save(),
                ),
                AppSpacing.gapMd,
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: InputDecoration(
                    labelText: l10n.profileCurrencyLabel,
                    prefixIcon: const Icon(CupertinoIcons.money_dollar_circle),
                  ),
                  items: [
                    if (!supportedCurrencyCodes.contains(_currency))
                      DropdownMenuItem(
                        value: _currency,
                        child: Text(_currency),
                      ),
                    for (final code in supportedCurrencyCodes)
                      DropdownMenuItem(
                        value: code,
                        child: Text('$code · ${currencyName(code, l10n)}'),
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
          label: l10n.commonSaveChanges,
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

String _profileErrorMessage(AppLocalizations l10n, Object? error) {
  if (error is AuthFailureException) return l10n.commonSignInToContinue;
  final code = error is ServerException ? error.code : null;
  return switch (code) {
    'invalid_display_name' => l10n.commonInvalidNameMax80,
    'invalid_currency' => l10n.commonInvalidCurrency,
    'authentication_required' => l10n.commonSignInToContinue,
    _ => l10n.profileErrorGeneric,
  };
}

String _pickerErrorMessage(AppLocalizations l10n, PlatformException e) =>
    switch (e.code) {
      'photo_access_denied' => l10n.pickerErrorPhotoAccessDenied,
      'camera_access_denied' => l10n.pickerErrorCameraAccessDenied,
      _ => l10n.pickerErrorGeneric,
    };
