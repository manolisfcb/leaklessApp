import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/categories_controller.dart';

/// Hex palette offered when creating a custom category. Stored as plain
/// strings on the model, so the domain stays UI-framework agnostic.
const List<String> categoryPaletteHex = [
  '#4E9BFA',
  '#34C7A5',
  '#F6A609',
  '#EF6C8B',
  '#9B6DF3',
  '#5AC8FA',
  '#7BC950',
  '#FF8A5B',
];

/// Form for creating or editing one custom category (name, icon, color).
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({this.category, super.key});

  /// The custom category being edited, or null when creating a new one.
  final TransactionCategory? category;

  /// Presents the form inside a [GlassBottomSheet].
  static Future<void> show(
    BuildContext context, {
    TransactionCategory? category,
  }) => GlassBottomSheet.show<void>(
    context,
    title: category == null
        ? context.l10n.categoryNew
        : context.l10n.categoryEdit,
    builder: (_) => CategoryFormSheet(category: category),
  );

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _iconKey;
  late String _colorHex;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    final icon = widget.category?.iconName;
    _iconKey = CategoryIcons.pickableKeys.contains(icon)
        ? icon!
        : CategoryIcons.pickableKeys.first;
    final color = widget.category?.colorHex;
    _colorHex = categoryPaletteHex.contains(color)
        ? color!
        : categoryPaletteHex.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saveFailed = false);
    final saved = await ref
        .read(categoriesControllerProvider.notifier)
        .save(
          category: widget.category,
          name: _name.text,
          iconName: _iconKey,
          colorHex: _colorHex,
        );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saveFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final saving = ref.watch(categoriesControllerProvider).isLoading;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.categoryNameLabel, style: AppTypography.labelLarge),
            AppSpacing.gapSm,
            TextFormField(
              key: const Key('category-name-field'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLength: 40,
              // Keep the field clear of the keyboard when it scrolls into view.
              scrollPadding: const EdgeInsets.only(bottom: 120),
              decoration: InputDecoration(
                hintText: l10n.categoryNameHint,
                prefixIcon: const Icon(CupertinoIcons.tag),
                counterText: '',
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.categoryNameRequired
                  : null,
              onFieldSubmitted: saving ? null : (_) => _save(),
            ),
            AppSpacing.gapXl,
            Text(l10n.categoryIconLabel, style: AppTypography.labelLarge),
            AppSpacing.gapSm,
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              children: [
                for (final key in CategoryIcons.pickableKeys)
                  _IconOption(
                    iconKey: key,
                    selected: _iconKey == key,
                    onTap: () => setState(() => _iconKey = key),
                  ),
              ],
            ),
            AppSpacing.gapXl,
            Text(l10n.categoryColorLabel, style: AppTypography.labelLarge),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final hex in categoryPaletteHex)
                  _ColorOption(
                    color: categoryColorFromHex(hex)!,
                    selected: _colorHex == hex,
                    onTap: () => setState(() => _colorHex = hex),
                  ),
              ],
            ),
            if (_saveFailed) ...[
              AppSpacing.gapLg,
              Text(
                l10n.categoriesOperationFailed,
                style: AppTypography.bodySmall.copyWith(color: colors.expense),
              ),
            ],
            AppSpacing.gapXl,
            GlassButton(
              key: const Key('category-save-button'),
              label: widget.category == null
                  ? l10n.categoryCreate
                  : l10n.categorySaveChanges,
              icon: CupertinoIcons.checkmark_alt,
              loading: saving,
              onPressed: saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Parses a `#RRGGBB` string into an opaque [Color]; null when unparseable.
Color? categoryColorFromHex(String? hex) {
  if (hex == null) return null;
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (value == null || hex.replaceFirst('#', '').length != 6) return null;
  return Color(0xFF000000 | value);
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      key: Key('category-icon-$iconKey'),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? colors.goalSoft : colors.glassFill,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(
            color: selected ? colors.primary : colors.glassBorder,
          ),
        ),
        child: Icon(
          CategoryIcons.forKey(iconKey),
          size: 20,
          color: selected ? colors.primary : colors.textSecondary,
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: context.colors.textPrimary, width: 3)
              : null,
        ),
        child: selected
            ? const Icon(
                CupertinoIcons.checkmark_alt,
                size: 18,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
