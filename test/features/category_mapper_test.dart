import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/models/transaction_category.dart';
import 'package:leakless/src/features/transactions/data/category_mapper.dart';

void main() {
  test('fromRow reads slug and category metadata', () {
    final category = CategoryMapper.fromRow({
      'id': 'cat-1',
      'household_id': 'household-1',
      'name': 'Comida',
      'slug': 'groceries',
      'icon_name': 'cart',
      'color_hex': '#112233',
      'is_default': true,
      'created_at': '2026-07-05T12:30:00Z',
    });

    expect(category.slug, 'groceries');
    expect(category.householdId, 'household-1');
    expect(category.isDefault, isTrue);
    expect(category.createdAt, DateTime.utc(2026, 7, 5, 12, 30));
  });

  test('toInsert and toUpdate write the supported columns', () {
    const category = TransactionCategory(
      id: 'cat-1',
      householdId: 'household-1',
      name: 'Mascotas',
      slug: 'pets',
      iconName: 'gift',
      colorHex: '#ABCDEF',
    );

    expect(CategoryMapper.toInsert(category), {
      'household_id': 'household-1',
      'name': 'Mascotas',
      'slug': 'pets',
      'icon_name': 'gift',
      'color_hex': '#ABCDEF',
      'is_default': false,
    });
    expect(CategoryMapper.toUpdate(category), {
      'name': 'Mascotas',
      'icon_name': 'gift',
      'color_hex': '#ABCDEF',
    });
  });
}
