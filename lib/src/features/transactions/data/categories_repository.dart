import '../../../core/dev/demo_data.dart';
import '../../../domain/models/transaction_category.dart';

/// Reads the household's transaction categories.
abstract interface class CategoriesRepository {
  Future<List<TransactionCategory>> fetchCategories();
}

/// Mock categories from [DemoData]. Replace with a Supabase implementation
/// (querying `categories`) when the backend is wired.
class MockCategoriesRepository implements CategoriesRepository {
  const MockCategoriesRepository();

  @override
  Future<List<TransactionCategory>> fetchCategories() async =>
      DemoData.categories;
}
