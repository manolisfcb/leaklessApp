import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../domain/models/income_source.dart';
import 'income_source_mapper.dart';

abstract interface class IncomeSourcesRepository {
  Stream<List<IncomeSource>> watch(String householdId);
  Future<IncomeSource> save(IncomeSource source);
  Future<void> archive(String sourceId);
}

class MockIncomeSourcesRepository implements IncomeSourcesRepository {
  final _controller = StreamController<List<IncomeSource>>.broadcast();
  final List<IncomeSource> _items = const [
    IncomeSource(
      id: 'source-salary',
      householdId: DemoData.householdId,
      name: 'Nómina',
      defaultCurrency: DemoData.currency,
      defaultAccountId: 'account-main',
    ),
  ];

  @override
  Stream<List<IncomeSource>> watch(String householdId) async* {
    yield _for(householdId);
    yield* _controller.stream.map((_) => _for(householdId));
  }

  List<IncomeSource> _for(String id) => List.unmodifiable(
    _items.where((item) => item.householdId == id).toList(),
  );

  @override
  Future<IncomeSource> save(IncomeSource source) async {
    final saved = source.id.isEmpty
        ? source.copyWith(id: 'source-${DateTime.now().microsecondsSinceEpoch}')
        : source;
    final index = _items.indexWhere((item) => item.id == saved.id);
    if (index < 0)
      _items.add(saved);
    else
      _items[index] = saved;
    _controller.add(_items);
    return saved;
  }

  @override
  Future<void> archive(String sourceId) async {
    final index = _items.indexWhere((item) => item.id == sourceId);
    if (index >= 0) _items[index] = _items[index].copyWith(isArchived: true);
    _controller.add(_items);
  }

  void dispose() => unawaited(_controller.close());
}

class SupabaseIncomeSourcesRepository implements IncomeSourcesRepository {
  SupabaseIncomeSourcesRepository(this.client);
  final SupabaseClient client;

  @override
  Stream<List<IncomeSource>> watch(String householdId) => client
      .from('income_sources')
      .stream(primaryKey: ['id'])
      .eq('household_id', householdId)
      .order('name')
      .map((rows) => rows.map(IncomeSourceMapper.fromRow).toList());

  @override
  Future<IncomeSource> save(IncomeSource source) async {
    final table = client.from('income_sources');
    final row = source.id.isEmpty
        ? await table.insert(IncomeSourceMapper.toRow(source)).select().single()
        : await table
              .update(IncomeSourceMapper.toRow(source))
              .eq('id', source.id)
              .select()
              .single();
    return IncomeSourceMapper.fromRow(row);
  }

  @override
  Future<void> archive(String sourceId) async {
    await client
        .from('income_sources')
        .update({'is_archived': true})
        .eq('id', sourceId);
  }
}
