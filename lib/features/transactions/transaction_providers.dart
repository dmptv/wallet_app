import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/transaction.dart';
import 'transaction_service.dart';

// Level 1: raw data, single source of truth.
class RawTransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    return ref.read(transactionServiceProvider).fetchTransactions();
  }
}

final rawTransactionsProvider =
    AsyncNotifierProvider<RawTransactionsNotifier, List<Transaction>>(
  RawTransactionsNotifier.new,
);

// Level 2: filter state, independent branch of the graph.
class TransactionFilter {
  final String? category;
  final double minAmount;

  const TransactionFilter({this.category, this.minAmount = 0});

  TransactionFilter copyWith({String? category, double? minAmount, bool clearCategory = false}) {
    return TransactionFilter(
      category: clearCategory ? null : (category ?? this.category),
      minAmount: minAmount ?? this.minAmount,
    );
  }
}

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setCategory(String? category) {
    state = category == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(category: category);
  }

  void setMinAmount(double minAmount) {
    state = state.copyWith(minAmount: minAmount);
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
  TransactionFilterNotifier.new,
);

// Level 3: derived from both level 1 and level 2.
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final raw = ref.watch(rawTransactionsProvider).value ?? const [];
  final filter = ref.watch(transactionFilterProvider);

  return raw.where((t) {
    if (filter.category != null && t.category != filter.category) return false;
    if (t.amount < filter.minAmount) return false;
    return true;
  }).toList();
});

// Level 4: grouped view derived from level 3.
final groupedByCategoryProvider = Provider<Map<String, List<Transaction>>>((ref) {
  final filtered = ref.watch(filteredTransactionsProvider);
  final map = <String, List<Transaction>>{};
  for (final t in filtered) {
    map.putIfAbsent(t.category, () => []).add(t);
  }
  return map;
});

// Level 5: aggregate totals derived from level 4.
final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final grouped = ref.watch(groupedByCategoryProvider);
  return grouped.map((category, txns) {
    final total = txns.fold<double>(0, (sum, t) => sum + t.amount);
    return MapEntry(category, total);
  });
});

// Level 6: single scalar derived from level 5.
final topCategoryProvider = Provider<String?>((ref) {
  final totals = ref.watch(categoryTotalsProvider);
  if (totals.isEmpty) return null;
  return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
});

// Level 6b: balance summary derived straight from level 3 (a sibling of the grouping branch).
final filteredBalanceProvider = Provider<double>((ref) {
  final filtered = ref.watch(filteredTransactionsProvider);
  return filtered.fold<double>(0, (sum, t) {
    return sum + (t.type == TransactionType.income ? t.amount : -t.amount);
  });
});

// Distinct categories available for the filter chips row — derived from raw data only,
// so it stays stable while the filter itself changes.
final availableCategoriesProvider = Provider<List<String>>((ref) {
  final raw = ref.watch(rawTransactionsProvider).value ?? const [];
  return raw.map((t) => t.category).toSet().toList()..sort();
});
