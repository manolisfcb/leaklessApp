import 'package:flutter/cupertino.dart';

import '../../domain/enums/transaction_enums.dart';

/// Maps domain string keys (stored on categories) to iOS-style line icons.
///
/// Keeping icon resolution here means the domain stores plain strings and the
/// UI never hardcodes per-screen icon lookups (quality rule #13).
abstract final class CategoryIcons {
  CategoryIcons._();

  static const IconData _fallback = CupertinoIcons.square_grid_2x2;

  static IconData forKey(String? key) => switch (key) {
    'cart' || 'groceries' => CupertinoIcons.cart,
    'restaurant' || 'dining' => CupertinoIcons.house_alt,
    'car' || 'transport' => CupertinoIcons.car_detailed,
    'subscriptions' => CupertinoIcons.creditcard,
    'home' => CupertinoIcons.house,
    'movie' || 'leisure' => CupertinoIcons.film,
    'savings' || 'future' => CupertinoIcons.money_dollar_circle,
    'health' => CupertinoIcons.heart,
    'gift' => CupertinoIcons.gift,
    _ => _fallback,
  };

  /// Icon used to represent a [TransactionPriority] in chips/legends.
  static IconData forPriority(TransactionPriority priority) => switch (priority) {
    TransactionPriority.necessity => CupertinoIcons.checkmark_shield,
    TransactionPriority.lifestyle => CupertinoIcons.sparkles,
    TransactionPriority.future => CupertinoIcons.money_dollar_circle,
    TransactionPriority.ant => CupertinoIcons.ant,
  };
}
