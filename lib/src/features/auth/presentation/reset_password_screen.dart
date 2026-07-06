import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_error_message.dart';
import '../application/auth_providers.dart';
import '../application/password_recovery_controller.dart';

/// Reached only through a password-recovery deep link (Supabase establishes a
/// recovery session, [passwordRecoveryPendingProvider] flips to `true`, and the
/// router pins the user here). Lets the user choose a new password; on success
/// the recovery flag clears and the router redirects into the app.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .submit(_password.text);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.resetPasswordUpdated)),
      );
      // Recovery flag is cleared by the controller; the router redirects away.
    }
  }

  /// Backing out of recovery signs the recovery session out so it can't linger.
  Future<void> _cancel() async {
    ref.read(passwordRecoveryPendingProvider.notifier).resolve();
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(resetPasswordControllerProvider);
    final loading = state.isLoading;
    final errorMessage = state.hasError ? authErrorMessage(state.error!) : null;

    return GlassScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(CupertinoIcons.lock_rotation, size: 56, color: colors.primary),
                AppSpacing.gapLg,
                Text(
                  l10n.resetPasswordTitle,
                  style: AppTypography.titleLarge,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapXs,
                Text(
                  l10n.resetPasswordBody,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapXl,
                GlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _password,
                        enabled: !loading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: l10n.resetPasswordNewLabel,
                          prefixIcon: const Icon(CupertinoIcons.lock),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: _confirm,
                        enabled: !loading,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: l10n.authConfirmPasswordHint,
                          prefixIcon: const Icon(CupertinoIcons.lock_shield),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            icon: Icon(
                              _obscureConfirm
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (value) => value != _password.text
                            ? l10n.authPasswordsDontMatch
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  AppSpacing.gapMd,
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
                          child: Text(
                            errorMessage,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                AppSpacing.gapXl,
                GlassButton(
                  label: l10n.resetPasswordSave,
                  loading: loading,
                  onPressed: loading ? null : _submit,
                ),
                AppSpacing.gapMd,
                TextButton(
                  onPressed: loading ? null : _cancel,
                  child: Text(
                    l10n.commonCancel,
                    style: AppTypography.labelLarge.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return context.l10n.resetPasswordNewRequired;
    if (password.length < 6) return context.l10n.authPasswordTooShort;
    return null;
  }
}
