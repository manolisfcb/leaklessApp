import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../household/application/invitation_intent_controller.dart';
import '../application/auth_controller.dart';
import '../application/auth_error_message.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';

final _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

/// Sign-in / sign-up screen. A single validated form toggles between the two
/// modes; on success the auth state changes and the router redirects to the app
/// (rule #4/#6 — no business logic here, just the controller + async state).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// Success / informational copy (email confirmation, reset sent) shown in a
  /// banner. Errors come from the controller's async state instead.
  String? _info;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _info = null;
      _confirm.clear();
    });
    // Drop any lingering error from the previous mode.
    ref.invalidate(authControllerProvider);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _info = null);

    final controller = ref.read(authControllerProvider.notifier);
    final email = _email.text.trim();

    if (_isSignUp) {
      final outcome = await controller.signUp(
        email: email,
        password: _password.text,
        displayName: _name.text.trim(),
      );
      if (!mounted) return;
      if (outcome == SignUpOutcome.emailConfirmationRequired) {
        setState(() {
          _info = context.l10n.authSignUpConfirmEmailInfo;
          _isSignUp = false;
          _confirm.clear();
        });
      }
      // SignUpOutcome.signedIn → the router redirects automatically.
    } else {
      await controller.signIn(email, _password.text);
    }
  }

  Future<void> _openForgotPassword() async {
    final sent = await GlassBottomSheet.show<bool>(
      context,
      title: context.l10n.authResetPasswordTitle,
      builder: (_) => _ForgotPasswordSheet(initialEmail: _email.text.trim()),
    );
    if (sent == true && mounted) {
      setState(() {
        _info = context.l10n.authResetLinkSentInfo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);
    final hasPendingInvitation =
        ref.watch(invitationIntentControllerProvider).token != null;
    final loading = state.isLoading;
    final errorMessage = state.hasError
        ? authErrorMessage(state.error!, l10n)
        : null;

    return GlassScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.liquid(colors),
                    boxShadow: AppShadows.glow(colors.goal),
                  ),
                  child: const Icon(
                    CupertinoIcons.drop_fill,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                AppSpacing.gapLg,
                Text('leakless', style: AppTypography.displayMedium),
                AppSpacing.gapXs,
                Text(
                  _isSignUp
                      ? l10n.authCreateAccountTitle
                      : hasPendingInvitation
                      ? l10n.authReviewInvitationTitle
                      : l10n.authWelcomeBackTitle,
                  style: AppTypography.bodyLarge.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (hasPendingInvitation) ...[
                  AppSpacing.gapLg,
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    borderColor: colors.goal.withValues(alpha: 0.35),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.person_2, color: colors.goal),
                        AppSpacing.gapMd,
                        Expanded(
                          child: Text(
                            l10n.authPendingInvitationHint,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                AppSpacing.gapXxl,
                GlassCard(
                  child: Column(
                    children: [
                      if (_isSignUp) ...[
                        _GlassField(
                          controller: _name,
                          hint: l10n.authNameHint,
                          icon: CupertinoIcons.person,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          validator: _validateName,
                        ),
                        AppSpacing.gapMd,
                      ],
                      _GlassField(
                        controller: _email,
                        hint: l10n.authEmailHint,
                        icon: CupertinoIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        validator: _validateEmail,
                      ),
                      AppSpacing.gapMd,
                      _GlassField(
                        controller: _password,
                        hint: l10n.authPasswordHint,
                        icon: CupertinoIcons.lock,
                        obscure: _obscurePassword,
                        textInputAction: _isSignUp
                            ? TextInputAction.next
                            : TextInputAction.done,
                        autofillHints: _isSignUp
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        validator: _validatePassword,
                        onSubmitted: _isSignUp ? null : (_) => _submit(),
                        suffix: _ObscureToggle(
                          obscured: _obscurePassword,
                          onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      if (_isSignUp) ...[
                        AppSpacing.gapMd,
                        _GlassField(
                          controller: _confirm,
                          hint: l10n.authConfirmPasswordHint,
                          icon: CupertinoIcons.lock_shield,
                          obscure: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: _validateConfirm,
                          onSubmitted: (_) => _submit(),
                          suffix: _ObscureToggle(
                            obscured: _obscureConfirm,
                            onTap: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_isSignUp) ...[
                  AppSpacing.gapXs,
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : _openForgotPassword,
                      child: Text(
                        l10n.authForgotPassword,
                        style: AppTypography.labelLarge.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
                if (errorMessage != null) ...[
                  AppSpacing.gapMd,
                  _MessageBanner(message: errorMessage, isError: true),
                ] else if (_info != null) ...[
                  AppSpacing.gapMd,
                  _MessageBanner(message: _info!, isError: false),
                ],
                AppSpacing.gapXl,
                GlassButton(
                  label: _isSignUp ? l10n.authCreateAccountCta : l10n.authSignInCta,
                  loading: loading,
                  onPressed: loading ? null : _submit,
                ),
                AppSpacing.gapMd,
                TextButton(
                  onPressed: loading ? null : _toggleMode,
                  child: Text(
                    _isSignUp
                        ? l10n.authToggleToSignIn
                        : l10n.authToggleToSignUp,
                    style: AppTypography.labelLarge.copyWith(
                      color: colors.primary,
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

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return context.l10n.authNameRequired;
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return context.l10n.authEmailRequired;
    if (!_emailRegExp.hasMatch(email)) return context.l10n.commonInvalidEmail;
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return context.l10n.authPasswordRequired;
    if (password.length < 6) return context.l10n.authPasswordTooShort;
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _password.text) return context.l10n.authPasswordsDontMatch;
    return null;
  }
}

/// The password-reset content shown inside a [GlassBottomSheet]. Manages its own
/// async state so it never bleeds into the main form's loading/error.
class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet({required this.initialEmail});

  final String initialEmail;

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_email.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        final message = authErrorMessage(error, context.l10n);
        setState(() {
          _loading = false;
          _error = message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.authForgotPasswordBody,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          AppSpacing.gapLg,
          _GlassField(
            controller: _email,
            hint: l10n.authEmailHint,
            icon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            onSubmitted: (_) => _send(),
            validator: (value) {
              final email = (value ?? '').trim();
              if (email.isEmpty) return l10n.authEmailRequired;
              if (!_emailRegExp.hasMatch(email)) return l10n.commonInvalidEmail;
              return null;
            },
          ),
          if (_error != null) ...[
            AppSpacing.gapMd,
            _MessageBanner(message: _error!, isError: true),
          ],
          AppSpacing.gapLg,
          GlassButton(
            label: l10n.authSendLink,
            loading: _loading,
            onPressed: _loading ? null : _send,
          ),
        ],
      ),
    );
  }
}

/// Password visibility toggle used as a field suffix.
class _ObscureToggle extends StatelessWidget {
  const _ObscureToggle({required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        obscured ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
        color: context.colors.textTertiary,
        size: 20,
      ),
      splashRadius: 20,
    );
  }
}

/// Inline error / info banner beneath the form.
class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = isError ? colors.expense : colors.income;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isError ? colors.expenseSoft : colors.incomeSoft,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? CupertinoIcons.exclamationmark_circle
                : CupertinoIcons.checkmark_circle,
            size: 18,
            color: accent,
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A frosted glass text field wired for [Form] validation.
class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.validator,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: AppRadii.cardRadius,
      borderSide: BorderSide(color: color),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: AppTypography.bodyLarge,
      cursorColor: colors.primary,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: colors.textSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: colors.glassFill,
        hintStyle: AppTypography.bodyLarge.copyWith(color: colors.textTertiary),
        errorStyle: AppTypography.bodySmall.copyWith(color: colors.expense),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: border(colors.glassBorder),
        enabledBorder: border(colors.glassBorder),
        focusedBorder: border(colors.primary),
        errorBorder: border(colors.expense),
        focusedErrorBorder: border(colors.expense),
      ),
    );
  }
}
