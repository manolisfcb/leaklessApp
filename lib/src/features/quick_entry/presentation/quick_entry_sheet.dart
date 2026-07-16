import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/category_names.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../shared/widgets/widgets.dart';
import '../../budgets/application/budget_alert_watcher.dart';
import '../../household/application/household_providers.dart';
import '../../transactions/application/categories_providers.dart';
import '../../transactions/presentation/category_form_sheet.dart';
import '../application/quick_entry_controller.dart';
import '../application/receipt_scan_providers.dart';
import '../data/receipt_scan_result.dart';
import '../data/receipt_scan_service.dart';

/// The Quick Entry form. Designed for one-handed use and shown inside a
/// [GlassBottomSheet]. It only collects input and delegates persistence to
/// [QuickEntryController] (quality rule #4/#6).
class QuickEntrySheet extends ConsumerStatefulWidget {
  const QuickEntrySheet({super.key});

  @override
  ConsumerState<QuickEntrySheet> createState() => _QuickEntrySheetState();
}

class _QuickEntrySheetState extends ConsumerState<QuickEntrySheet> {
  final _picker = ImagePicker();
  final _note = TextEditingController();

  int _cents = 0;
  ResponsibleType _responsible = ResponsibleType.me;
  TransactionPriority _priority = TransactionPriority.necessity;
  String? _categoryId;
  String? _currency;

  /// Purchase date lifted from a scanned receipt; null means "now".
  DateTime? _occurredAt;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _press(int digit) =>
      setState(() => _cents = (_cents * 10 + digit).clamp(0, 99999999));
  void _backspace() => setState(() => _cents ~/= 10);

  Future<void> _save() async {
    if (_cents == 0) return;
    final l10n = context.l10n;
    final note = _note.text.trim();
    final ok = await ref
        .read(quickEntryControllerProvider.notifier)
        .submit(
          amountMinorUnits: _cents,
          type: TransactionType.expense,
          priority: _priority,
          responsible: _responsible,
          currency: _currency,
          categoryId: _categoryId,
          description: note.isEmpty ? null : note,
          occurredAt: _occurredAt,
        );
    if (ok && mounted) {
      _showBudgetAlertIfAny();
      Navigator.of(context).pop();
    } else if (mounted) {
      _showMessage(l10n.quickEntrySaveError);
    }
  }

  /// Surfaces the in-app half of a budget alert fired by this save. Shown on
  /// the root [ScaffoldMessenger], so it outlives the sheet being popped.
  void _showBudgetAlertIfAny() {
    final trigger = ref.read(budgetAlertNoticeProvider.notifier).consume();
    if (trigger == null) return;
    final categories =
        ref.read(categoriesProvider).asData?.value ??
        const <TransactionCategory>[];
    TransactionCategory? category;
    for (final c in categories) {
      if (c.id == trigger.budget.categoryId) {
        category = c;
        break;
      }
    }
    final l10n = context.l10n;
    final name = category == null ? null : categoryDisplayName(category, l10n);
    final message = trigger.isLimitReached
        ? (name == null
              ? l10n.budgetLimitReachedBannerGeneric
              : l10n.budgetLimitReachedBanner(name))
        : (name == null
              ? l10n.budgetAlertBannerGeneric(trigger.pctSpent)
              : l10n.budgetAlertBanner(trigger.pctSpent, name));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Lets the user snap a receipt (or pick an existing photo), runs it through
  /// Gemini OCR and prefills whatever the scan recovered.
  Future<void> _scanReceipt() async {
    final l10n = context.l10n;
    final source = await _chooseImageSource();
    if (source == null) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
    } on PlatformException catch (e) {
      _showMessage(_pickerErrorMessage(e, l10n));
      return;
    }
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    final currency =
        _currency ??
        ref.read(currentHouseholdProvider).asData?.value?.currency ??
        'USD';
    final categories =
        ref.read(categoriesProvider).asData?.value ??
        const <TransactionCategory>[];

    ReceiptScanResult? result;
    try {
      result = await ref
          .read(receiptScanControllerProvider.notifier)
          .scan(
            bytes,
            currency: currency,
            mimeType: _receiptMimeType(picked),
            categoryNames: [
              for (final c in categories) categoryDisplayName(c, l10n),
            ],
          );
    } catch (e) {
      _showMessage(_scanErrorMessage(e, l10n));
      return;
    }
    if (!mounted || result == null) return;

    if (result.isEmpty) {
      _showMessage(l10n.quickEntryScanEmpty);
      return;
    }
    _applyScan(result, categories);
  }

  /// Folds a [ReceiptScanResult] into the form, touching only fields it filled.
  void _applyScan(
    ReceiptScanResult result,
    List<TransactionCategory> categories,
  ) {
    setState(() {
      if (result.amount != null) {
        _cents = result.amount!.minorUnits.abs();
        _currency = result.amount!.currency;
      }
      if (result.description != null) _note.text = result.description!;
      _occurredAt = result.occurredAt;
      final match = _matchCategory(result.categoryName, categories);
      if (match != null) _categoryId = match.id;
    });
    _showMessage(context.l10n.quickEntryScanSuccess);
  }

  TransactionCategory? _matchCategory(
    String? name,
    List<TransactionCategory> categories,
  ) {
    if (name == null) return null;
    final target = name.trim().toLowerCase();
    for (final c in categories) {
      final localized = categoryDisplayName(c, context.l10n).toLowerCase();
      if (localized == target || c.name.trim().toLowerCase() == target) {
        return c;
      }
    }
    return null;
  }

  Future<ImageSource?> _chooseImageSource() =>
      GlassBottomSheet.show<ImageSource>(
        context,
        title: context.l10n.quickEntryScanReceipt,
        builder: (sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SourceTile(
              icon: CupertinoIcons.camera,
              label: context.l10n.quickEntryTakePhoto,
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceTile(
              icon: CupertinoIcons.photo,
              label: context.l10n.quickEntryPickFromGallery,
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      );

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currency =
        _currency ??
        ref.watch(currentHouseholdProvider).asData?.value?.currency ??
        'USD';
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
    final saving = ref.watch(quickEntryControllerProvider).isLoading;
    final scanEnabled = ref.watch(receiptScanEnabledProvider);
    final scanning = ref.watch(receiptScanControllerProvider).isLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Text(
            MoneyFormatter.format(_cents, currencyCode: currency),
            style: AppTypography.displayLarge.copyWith(
              color: _cents == 0 ? colors.textTertiary : colors.textPrimary,
            ),
          ),
        ),
        AppSpacing.gapLg,
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (scanEnabled) ...[
                  GlassButton(
                    label: scanning
                        ? context.l10n.quickEntryScanningReceipt
                        : context.l10n.quickEntryScanReceipt,
                    icon: CupertinoIcons.camera_viewfinder,
                    variant: GlassButtonVariant.glass,
                    loading: scanning,
                    onPressed: scanning || saving ? null : _scanReceipt,
                  ),
                  AppSpacing.gapLg,
                ],
                DropdownButtonFormField<String>(
                  key: const Key('expense-currency-field'),
                  initialValue: currency,
                  decoration: InputDecoration(
                    labelText: context.l10n.currencyLabel,
                  ),
                  items: const ['CAD', 'USD']
                      .map(
                        (code) =>
                            DropdownMenuItem(value: code, child: Text(code)),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) => setState(() {
                          _currency = value;
                        }),
                ),
                AppSpacing.gapXl,
                const _Label('¿Quién?'),
                AppSpacing.gapSm,
                _Segmented<ResponsibleType>(
                  value: _responsible,
                  onChanged: (v) => setState(() => _responsible = v),
                  options: {
                    for (final r in ResponsibleType.values)
                      r: r.localizedLabel(context.l10n),
                  },
                ),
                AppSpacing.gapXl,
                const _Label('Categoría'),
                AppSpacing.gapSm,
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: CategoryChip(
                            label: categoryDisplayName(c, context.l10n),
                            icon: CategoryIcons.forKey(c.iconName),
                            selected: _categoryId == c.id,
                            onTap: () => setState(
                              () => _categoryId = _categoryId == c.id
                                  ? null
                                  : c.id,
                            ),
                          ),
                        ),
                      CategoryChip(
                        label: context.l10n.categoryNew,
                        icon: CupertinoIcons.add,
                        selected: false,
                        onTap: () => CategoryFormSheet.show(context),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapLg,
                const _Label('Nota'),
                AppSpacing.gapSm,
                TextField(
                  controller: _note,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  // Keep the field clear of the keyboard when it auto-scrolls into view.
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Descripción (ej. comercio)',
                    prefixIcon: Icon(CupertinoIcons.text_alignleft),
                    counterText: '',
                  ),
                ),
                AppSpacing.gapXl,
                const _Label('Prioridad'),
                AppSpacing.gapSm,
                _PriorityPicker(
                  value: _priority,
                  onChanged: (v) => setState(() => _priority = v),
                ),
                AppSpacing.gapXl,
                _Keypad(onDigit: _press, onBackspace: _backspace),
                AppSpacing.gapLg,
                GlassButton(
                  label: 'Guardar',
                  icon: CupertinoIcons.checkmark_alt,
                  loading: saving,
                  onPressed: _cents == 0 || saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.labelLarge.copyWith(
      color: context.colors.textSecondary,
    ),
  );
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final Map<T, String> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        children: [
          for (final entry in options.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entry.key == value
                        ? colors.primary
                        : Colors.transparent,
                    borderRadius: AppRadii.pillRadius,
                  ),
                  child: Text(
                    entry.value,
                    style: AppTypography.labelLarge.copyWith(
                      color: entry.key == value
                          ? Colors.white
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriorityPicker extends StatelessWidget {
  const _PriorityPicker({required this.value, required this.onChanged});
  final TransactionPriority value;
  final ValueChanged<TransactionPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (final p in TransactionPriority.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: p == value ? colors.goalSoft : colors.glassFill,
                    borderRadius: AppRadii.cardRadius,
                    border: Border.all(
                      color: p == value ? colors.primary : colors.glassBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        CategoryIcons.forPriority(p),
                        size: 18,
                        color: p == value
                            ? colors.primary
                            : colors.textSecondary,
                      ),
                      AppSpacing.gapXs,
                      Text(
                        p.localizedLabel(context.l10n),
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(
                          color: p == value
                              ? colors.primary
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget key(Widget child, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.glassFill,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: colors.glassBorder),
        ),
        child: child,
      ),
    );

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.9,
      children: [
        for (var i = 1; i <= 9; i++)
          key(Text('$i', style: AppTypography.titleLarge), () => onDigit(i)),
        const SizedBox.shrink(),
        key(Text('0', style: AppTypography.titleLarge), () => onDigit(0)),
        key(
          Icon(CupertinoIcons.delete_left, color: colors.textSecondary),
          onBackspace,
        ),
      ],
    );
  }
}

/// A tappable row used in the "Escanear recibo" source chooser (camera/gallery).
class _SourceTile extends StatelessWidget {
  const _SourceTile({
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
          Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: colors.textTertiary,
          ),
        ],
      ),
    );
  }
}

/// Maps an image-picker platform error to a friendly, actionable message.
String _pickerErrorMessage(PlatformException e, AppLocalizations l10n) =>
    switch (e.code) {
      'photo_access_denied' => l10n.quickEntryScanPhotoAccessDenied,
      'camera_access_denied' => l10n.quickEntryScanCameraAccessDenied,
      _ => l10n.quickEntryScanPickerError,
    };

/// Maps a receipt scan failure to a friendly message.
String _scanErrorMessage(Object error, AppLocalizations l10n) {
  if (error is ReceiptScanException) {
    return switch (error.code) {
      'network' => l10n.quickEntryScanNetworkError,
      'rate_limited' => l10n.quickEntryScanRateLimited,
      'unauthorized' => l10n.quickEntryScanUnauthorized,
      'invalid_image' => l10n.quickEntryScanInvalidImage,
      'unavailable' => l10n.quickEntryScanUnavailable,
      _ => error.message,
    };
  }
  return l10n.quickEntryScanGenericError;
}

/// `image_picker` normally reports a MIME type. Some platform implementations
/// leave it null, so fall back to the selected file extension.
String _receiptMimeType(XFile file) {
  final reported = file.mimeType?.toLowerCase();
  if (reported != null && reported.startsWith('image/')) return reported;
  final path = file.path.toLowerCase();
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.webp')) return 'image/webp';
  if (path.endsWith('.heic') || path.endsWith('.heif')) return 'image/heic';
  return 'image/jpeg';
}
