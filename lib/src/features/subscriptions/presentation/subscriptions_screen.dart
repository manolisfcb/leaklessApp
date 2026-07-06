import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/enum_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../domain/models/subscription_item.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../shared/widgets/widgets.dart';
import '../../transactions/application/categories_providers.dart';
import '../application/subscriptions_providers.dart';
import 'subscription_form_sheet.dart';

/// Recurring expenses: list of subscriptions and fixed charges with an optional
/// local reminder before each charge. Create, edit (tap) and delete are here.
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final subscriptions = ref.watch(subscriptionsProvider);
    final categories = ref.watch(categoriesByIdProvider);

    ref.listen<AsyncValue<void>>(subscriptionsControllerProvider, (
      previous,
      next,
    ) {
      if (!next.hasError || identical(previous?.error, next.error)) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.subscriptionsOperationFailed)),
        );
    });

    return GlassScaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptionsTitle),
        actions: [
          IconButton(
            tooltip: l10n.subscriptionNew,
            icon: const Icon(CupertinoIcons.add),
            onPressed: () => SubscriptionFormSheet.show(context),
          ),
        ],
      ),
      body: subscriptions.when(
        loading: () => const AppLoader(),
        error: (_, _) => AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: l10n.subscriptionsLoadFailed,
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              icon: CupertinoIcons.creditcard,
              title: l10n.subscriptionsEmptyTitle,
              message: l10n.subscriptionsEmptyMessage,
              actionLabel: l10n.subscriptionCreate,
              onAction: () => SubscriptionFormSheet.show(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              120,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => AppSpacing.gapMd,
            itemBuilder: (context, i) => _SubscriptionCard(
              subscription: items[i],
              category: categories[items[i].categoryId],
              onTap: () => SubscriptionFormSheet.show(
                context,
                subscription: items[i],
              ),
              onDelete: () => _confirmDelete(context, ref, items[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SubscriptionItem subscription,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.subscriptionDeleteTitle),
        content: Text(l10n.subscriptionDeleteWarning(subscription.name)),
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
    if (confirmed == true) {
      await ref
          .read(subscriptionsControllerProvider.notifier)
          .delete(subscription.id);
    }
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.onTap,
    required this.onDelete,
    this.category,
  });

  final SubscriptionItem subscription;
  final TransactionCategory? category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final nextCharge = subscription.nextChargeAt;

    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.goal.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CategoryIcons.forKey(category?.iconName),
              size: 20,
              color: colors.goal,
            ),
          ),
          AppSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subscription.name,
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    if (subscription.reminderEnabled)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Icon(
                          CupertinoIcons.bell_fill,
                          size: 15,
                          color: colors.primary,
                        ),
                      ),
                  ],
                ),
                AppSpacing.gapXs,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AmountText(
                      money: subscription.amount,
                      style: AppTypography.titleLarge,
                    ),
                    Text(
                      ' · ${subscription.frequency.localizedLabel(l10n)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (nextCharge != null) ...[
                  AppSpacing.gapXs,
                  Text(
                    '${l10n.subscriptionNextChargeLabel}: '
                    '${DateFormat.yMMMMd().format(nextCharge)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.subscriptionDeleteTitle,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              CupertinoIcons.trash,
              size: 18,
              color: colors.textSecondary,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
