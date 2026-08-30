import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/transaction.dart';
import 'transaction_service.dart';

// Level 1: raw data from the real Blockscout API — single source of truth.
class RawTransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final address = ref.watch(watchedAddressProvider);
    return ref.read(transactionServiceProvider).fetchTransactions(address);
  }
}

final rawTransactionsProvider =
    AsyncNotifierProvider<RawTransactionsNotifier, List<Transaction>>(
  RawTransactionsNotifier.new,
);

// Level 2: filter state, independent branch of the graph.
class TransactionFilter {
  final TransactionDirection? direction;
  final double minValueEth;

  const TransactionFilter({this.direction, this.minValueEth = 0});

  TransactionFilter copyWith({
    TransactionDirection? direction,
    double? minValueEth,
    bool clearDirection = false,
  }) {
    return TransactionFilter(
      direction: clearDirection ? null : (direction ?? this.direction),
      minValueEth: minValueEth ?? this.minValueEth,
    );
  }
}

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setDirection(TransactionDirection? direction) {
    state = direction == null
        ? state.copyWith(clearDirection: true)
        : state.copyWith(direction: direction);
  }

  void setMinValueEth(double minValueEth) {
    state = state.copyWith(minValueEth: minValueEth);
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
    if (filter.direction != null && t.direction != filter.direction) return false;
    if (t.valueEth < filter.minValueEth) return false;
    return true;
  }).toList();
});

// Level 4: grouped view derived from level 3.
final groupedByDirectionProvider = Provider<Map<TransactionDirection, List<Transaction>>>((ref) {
  final filtered = ref.watch(filteredTransactionsProvider);
  final map = <TransactionDirection, List<Transaction>>{};
  for (final t in filtered) {
    map.putIfAbsent(t.direction, () => []).add(t);
  }
  return map;
});

// Level 5: aggregate totals derived from level 4.
final directionTotalsProvider = Provider<Map<TransactionDirection, double>>((ref) {
  final grouped = ref.watch(groupedByDirectionProvider);
  return grouped.map((direction, txns) {
    final total = txns.fold<double>(0, (sum, t) => sum + t.valueEth);
    return MapEntry(direction, total);
  });
});

// Level 6: net balance change derived from level 5.
final filteredBalanceProvider = Provider<double>((ref) {
  final totals = ref.watch(directionTotalsProvider);
  final incoming = totals[TransactionDirection.incoming] ?? 0;
  final outgoing = totals[TransactionDirection.outgoing] ?? 0;
  return incoming - outgoing;
});

// Distinct set of counterparty addresses — derived from raw data only, so it
// stays stable while the filter itself changes.
final counterpartyCountProvider = Provider<int>((ref) {
  final raw = ref.watch(rawTransactionsProvider).value ?? const [];
  final address = ref.watch(watchedAddressProvider).toLowerCase();
  final counterparties = raw.map((t) {
    return t.from.toLowerCase() == address ? t.to.toLowerCase() : t.from.toLowerCase();
  }).toSet();
  return counterparties.length;
});
