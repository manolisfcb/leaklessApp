import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/category_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/categories_controller.dart';
import '../application/categories_providers.dart';
import 'category_form_sheet.dart';

/// Category management: defaults are listed read-only; custom categories can
/// be created, edited and deleted (deleting cascades their budgets).
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider);

    return GlassScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsCategories),
        actions: [
          IconButton(
            tooltip: l10n.categoryNew,
            icon: const Icon(CupertinoIcons.add),
            onPressed: () => CategoryFormSheet.show(context),
          ),
        ],
      ),
      body: categories.when(
        loading: () => const AppLoader(),
        error: (_, _) => AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: l10n.categoriesLoadFailed,
        ),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            120,
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => AppSpacing.gapSm,
          itemBuilder: (context, i) => _CategoryTile(
            category: items[i],
            onEdit: () => CategoryFormSheet.show(context, category: items[i]),
            onDelete: () => _confirmDelete(context, ref, items[i]),
          ),
        ),
      ),
    );
  }

  /// Deletion cascades the category's budgets, so the confirmation says so.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionCategory category,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.categoryDeleteTitle),
        content: Text(
          l10n.categoryDeleteWarning(categoryDisplayName(category, l10n)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(categoriesControllerProvider.notifier)
        .delete(category.id);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.categoriesOperationFailed)));
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final custom = !category.isDefault;
    final accent = categoryColorFromHex(category.colorHex) ?? colors.primary;

    return GlassCard(
      onTap: custom ? onEdit : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CategoryIcons.forKey(category.iconName),
              size: 18,
              color: accent,
            ),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Text(
              categoryDisplayName(category, context.l10n),
              style: AppTypography.titleMedium,
            ),
          ),
          if (custom)
            IconButton(
              tooltip: context.l10n.categoryDeleteTitle,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                CupertinoIcons.trash,
                size: 18,
                color: colors.textSecondary,
              ),
              onPressed: onDelete,
            )
          else
            Text(
              context.l10n.categoryDefaultBadge,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}
