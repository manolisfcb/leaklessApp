import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/category_names.dart';
import '../../../../core/l10n/enum_labels.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../domain/enums/transaction_enums.dart';
import '../../../../domain/models/transaction.dart';
import '../../../../domain/models/transaction_category.dart';
import '../../../../shared/widgets/widgets.dart';

/// A single transaction row, reused on the dashboard's recent list and the full
/// history screen (quality rule #2).
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    this.category,
    this.showDate = false,
    super.key,
  });

  final Transaction transaction;
  final TransactionCategory? category;

  /// The full History screen shows the transaction date. The compact Dashboard
  /// list leaves it out because that surface is intentionally denser.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isExpense = transaction.isExpense;
    final accent = isExpense
        ? colors.expense
        : (transaction.isIncome ? colors.income : colors.textSecondary);
    final title = transaction.description?.trim().isNotEmpty ?? false
        ? transaction.description!
        : category == null
        ? context.l10n.transactionFallbackTitle
        : categoryDisplayName(category!, context.l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: AppRadii.pillRadius,
            ),
            child: Icon(
              CategoryIcons.forKey(category?.iconName),
              size: 20,
              color: accent,
            ),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                if (showDate) ...[
                  Text(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(transaction.occurredAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(
                  '${transaction.priority.localizedLabel(context.l10n)} · ${transaction.responsible.localizedLabel(context.l10n)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          AmountText(
            money: transaction.amount,
            style: AppTypography.titleMedium,
            color: accent,
            signDisplay: transaction.type == TransactionType.transfer
                ? SignDisplay.none
                : SignDisplay.always,
          ),
        ],
      ),
    );
  }
}
