import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/account_deletion_controller.dart';

/// How the account relates to its household — decides the deletion consequence
/// copy and whether we must confirm destroying shared data.
enum DeleteAccountMode {
  /// Sole member: deleting the account deletes the household and all its data.
  soloOwner,

  /// Owner with a partner: ownership transfers, shared data is preserved.
  sharedOwner,

  /// Non-owner member: the user leaves; the partner keeps everything.
  member,
}

/// Confirmation + re-authentication sheet for permanent account deletion.
///
/// Requires the user's current password (re-auth) before calling the
/// server-side [AccountDeletionController]. On success the session is cleared
/// and the router redirects to auth, so the sheet just closes.
class DeleteAccountSheet extends ConsumerStatefulWidget {
  const DeleteAccountSheet({required this.mode, super.key});

  final DeleteAccountMode mode;

  /// Shows the sheet; returns `true` when the account was deleted.
  static Future<bool> show(
    BuildContext context, {
    required DeleteAccountMode mode,
  }) async {
    final deleted = await GlassBottomSheet.show<bool>(
      context,
      title: 'Eliminar cuenta',
      builder: (_) => DeleteAccountSheet(mode: mode),
    );
    return deleted ?? false;
  }

  @override
  ConsumerState<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<DeleteAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _acknowledged = false;
  bool _loading = false;
  String? _error;

  bool get _isSolo => widget.mode == DeleteAccountMode.soloOwner;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSolo && !_acknowledged) {
      setState(
        () => _error = 'Confirma que entiendes que se borrarán los datos.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await ref
        .read(accountDeletionControllerProvider.notifier)
        .deleteAccount(
          password: _password.text,
          confirmHouseholdDeletion: _isSolo,
        );
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _loading = false;
      _error = _deleteErrorMessage(
        ref.read(accountDeletionControllerProvider).error,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _consequenceCopy,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          AppSpacing.gapLg,
          TextFormField(
            controller: _password,
            enabled: !_loading,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Tu contraseña',
              prefixIcon: const Icon(CupertinoIcons.lock),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  size: 20,
                ),
              ),
            ),
            validator: (value) =>
                (value ?? '').isEmpty ? 'Escribe tu contraseña.' : null,
            onFieldSubmitted: (_) => _delete(),
          ),
          if (_isSolo) ...[
            AppSpacing.gapMd,
            CheckboxListTile(
              value: _acknowledged,
              onChanged: _loading
                  ? null
                  : (v) => setState(() => _acknowledged = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Entiendo que se eliminarán mi hogar y todos sus datos.',
                style: AppTypography.bodySmall,
              ),
            ),
          ],
          if (_error != null) ...[
            AppSpacing.gapMd,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 18,
                  color: colors.expense,
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    _error!,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.expense,
                    ),
                  ),
                ),
              ],
            ),
          ],
          AppSpacing.gapLg,
          GlassButton(
            label: 'Eliminar mi cuenta',
            icon: CupertinoIcons.trash,
            accent: colors.expense,
            loading: _loading,
            onPressed: _loading ? null : _delete,
          ),
        ],
      ),
    );
  }

  String get _consequenceCopy => switch (widget.mode) {
    DeleteAccountMode.soloOwner =>
      'Eres la única persona en tu hogar. Al eliminar tu cuenta se borrarán '
          'también el hogar y todos sus datos (movimientos, presupuestos, metas '
          'y suscripciones). Esta acción no se puede deshacer.',
    DeleteAccountMode.sharedOwner =>
      'La propiedad del hogar pasará a tu pareja, que conservará todos los '
          'datos compartidos. Se eliminará tu cuenta y tu perfil. Esta acción no '
          'se puede deshacer.',
    DeleteAccountMode.member =>
      'Saldrás del hogar; tu pareja conservará todos los datos compartidos. Se '
          'eliminará tu cuenta y tu perfil. Esta acción no se puede deshacer.',
  };
}

String _deleteErrorMessage(Object? error) {
  if (error is AuthFailureException) return 'Contraseña incorrecta.';
  final code = error is ServerException ? error.code : null;
  return switch (code) {
    'authentication_required' => 'Inicia sesión de nuevo para continuar.',
    'household_deletion_not_confirmed' =>
      'Confirma que entiendes que se borrarán los datos del hogar.',
    _ => 'No pudimos eliminar tu cuenta. Inténtalo de nuevo.',
  };
}
