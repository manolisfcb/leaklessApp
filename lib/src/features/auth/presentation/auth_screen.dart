import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_controller.dart';

/// Auth placeholder. The structure is real (controller + async state), but the
/// fields are visual until Supabase Auth screens are built out.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController(text: 'demo@leakless.app');
  final _password = TextEditingController(text: 'demo1234');
  bool _isSignUp = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(authControllerProvider.notifier);
    if (_isSignUp) {
      await controller.signUp(_email.text.trim(), _password.text);
    } else {
      await controller.signIn(_email.text.trim(), _password.text);
    }
    // On success the Fake/Supabase auth state changes and the router redirects
    // to the dashboard automatically.
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;

    return GlassScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
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
                _isSignUp ? 'Crea tu cuenta' : 'Bienvenido de vuelta',
                style: AppTypography.bodyLarge.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              AppSpacing.gapXxl,
              GlassCard(
                child: Column(
                  children: [
                    _GlassField(
                      controller: _email,
                      hint: 'Correo electrónico',
                      icon: CupertinoIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    AppSpacing.gapMd,
                    _GlassField(
                      controller: _password,
                      hint: 'Contraseña',
                      icon: CupertinoIcons.lock,
                      obscure: true,
                    ),
                  ],
                ),
              ),
              if (state.hasError) ...[
                AppSpacing.gapMd,
                Text(
                  'No pudimos continuar. Revisa tus datos e inténtalo de nuevo.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: colors.expense),
                ),
              ],
              AppSpacing.gapXl,
              GlassButton(
                label: _isSignUp ? 'Crear cuenta' : 'Iniciar sesión',
                loading: loading,
                onPressed: loading ? null : _submit,
              ),
              AppSpacing.gapMd,
              TextButton(
                onPressed: loading
                    ? null
                    : () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp
                      ? '¿Ya tienes cuenta? Inicia sesión'
                      : '¿Sin cuenta? Regístrate',
                  style: AppTypography.labelLarge.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: colors.textSecondary, size: 20),
        filled: true,
        fillColor: colors.glassFill,
        hintStyle: AppTypography.bodyLarge.copyWith(color: colors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: BorderSide(color: colors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: BorderSide(color: colors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: BorderSide(color: colors.primary),
        ),
      ),
    );
  }
}
