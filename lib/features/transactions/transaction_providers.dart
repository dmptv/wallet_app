import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wallet_config.dart';
import 'models/transaction.dart';
import 'transaction_cache.dart';
import 'transaction_service.dart';

enum TransactionSyncStatus { idle, syncing, offline }

class TransactionSyncNotifier extends Notifier<TransactionSyncStatus> {
  @override
  TransactionSyncStatus build() => TransactionSyncStatus.idle;

  void setStatus(TransactionSyncStatus status) => state = status;
}

final transactionSyncStatusProvider =
    NotifierProvider<TransactionSyncNotifier, TransactionSyncStatus>(
  TransactionSyncNotifier.new,
);

// Level 1: raw data — offline-first. Cached data (if any) is shown
// immediately, then a live fetch runs in the background and replaces it.
// If the background fetch fails, the cached data stays on screen and
// transactionSyncStatusProvider flips to .offline instead of surfacing an
// error state.
class RawTransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final address = ref.watch(watchedAddressProvider);
    final cached = await ref.read(transactionCacheProvider).load(address);

    if (cached != null) {
      // Don't await — let the cached data render first, sync in the background.
      Future.microtask(refresh);
      return cached;
    }

    return _fetchAndCache(address);
  }

  Future<void> refresh() async {
    final address = ref.read(watchedAddressProvider);
    final syncNotifier = ref.read(transactionSyncStatusProvider.notifier);
    syncNotifier.setStatus(TransactionSyncStatus.syncing);

    try {
      final fresh = await _fetchAndCache(address);
      if (ref.mounted) {
        state = AsyncValue.data(fresh);
        syncNotifier.setStatus(TransactionSyncStatus.idle);
      }
    } catch (e, st) {
      if (!ref.mounted) return;
      syncNotifier.setStatus(TransactionSyncStatus.offline);
      // Keep whatever data is already on screen (cached or previous fetch);
      // only surface a hard error state if we have nothing to show at all.
      if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<List<Transaction>> _fetchAndCache(String address) async {
    final fresh = await ref.read(transactionServiceProvider).fetchTransactions(address);
    await ref.read(transactionCacheProvider).save(address, fresh);
    return fresh;
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
