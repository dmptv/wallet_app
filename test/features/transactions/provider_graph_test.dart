import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_app/features/transactions/models/transaction.dart';
import 'package:wallet_app/features/transactions/transaction_cache.dart';
import 'package:wallet_app/features/transactions/transaction_providers.dart';
import 'package:wallet_app/features/transactions/transaction_service.dart';
import 'package:wallet_app/wallet_config.dart';

const _address = '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045';

Transaction _tx({
  required String hash,
  required TransactionDirection direction,
  required double valueEth,
}) {
  return Transaction(
    hash: hash,
    from: direction == TransactionDirection.incoming ? '0xsender' : _address,
    to: direction == TransactionDirection.incoming ? _address : '0xreceiver',
    valueWei: BigInt.from((valueEth * 1e18).round()),
    gasUsed: 21000,
    status: 'ok',
    timestamp: DateTime.utc(2026, 1, 1),
    direction: direction,
  );
}

// 3 incoming (1.0 + 2.0 + 0.5 = 3.5) and 2 outgoing (1.5 + 0.25 = 1.75).
final _fixture = [
  _tx(hash: '0xin1', direction: TransactionDirection.incoming, valueEth: 1.0),
  _tx(hash: '0xin2', direction: TransactionDirection.incoming, valueEth: 2.0),
  _tx(hash: '0xin3', direction: TransactionDirection.incoming, valueEth: 0.5),
  _tx(hash: '0xout1', direction: TransactionDirection.outgoing, valueEth: 1.5),
  _tx(hash: '0xout2', direction: TransactionDirection.outgoing, valueEth: 0.25),
];

class FixedTransactionService implements TransactionService {
  @override
  Future<List<Transaction>> fetchTransactions(String address) async => _fixture;
}

class NoopTransactionCache implements TransactionCache {
  @override
  Future<List<Transaction>?> load(String address) async => null;

  @override
  Future<void> save(String address, List<Transaction> transactions) async {}
}

void main() {
  test('a filter change propagates through the whole provider graph', () async {
    final container = ProviderContainer(overrides: [
      watchedAddressProvider.overrideWithValue(_address),
      transactionServiceProvider.overrideWithValue(FixedTransactionService()),
      transactionCacheProvider.overrideWithValue(NoopTransactionCache()),
    ]);
    addTearDown(container.dispose);

    // Keep every level of the graph alive so state updates propagate down
    // instead of the provider being disposed between reads.
    container.listen(rawTransactionsProvider, (_, _) {});
    container.listen(filteredTransactionsProvider, (_, _) {});
    container.listen(groupedByDirectionProvider, (_, _) {});
    container.listen(directionTotalsProvider, (_, _) {});
    container.listen(filteredBalanceProvider, (_, _) {});

    await container.read(rawTransactionsProvider.future);

    // Level 3-6, no filter applied: everything passes through.
    expect(container.read(filteredTransactionsProvider).length, 5);
    expect(container.read(groupedByDirectionProvider)[TransactionDirection.incoming]!.length, 3);
    expect(container.read(groupedByDirectionProvider)[TransactionDirection.outgoing]!.length, 2);
    expect(container.read(directionTotalsProvider)[TransactionDirection.incoming], closeTo(3.5, 1e-9));
    expect(container.read(directionTotalsProvider)[TransactionDirection.outgoing], closeTo(1.75, 1e-9));
    expect(container.read(filteredBalanceProvider), closeTo(3.5 - 1.75, 1e-9));

    // Change the filter at level 2 — everything below must recompute.
    container.read(transactionFilterProvider.notifier).setDirection(TransactionDirection.incoming);

    expect(container.read(filteredTransactionsProvider).length, 3,
        reason: 'level 3 (filtered) should drop outgoing transactions');
    expect(container.read(groupedByDirectionProvider).containsKey(TransactionDirection.outgoing), isFalse,
        reason: 'level 4 (grouped) should no longer have an outgoing bucket');
    expect(container.read(directionTotalsProvider)[TransactionDirection.outgoing], isNull,
        reason: 'level 5 (totals) should have no outgoing entry');
    expect(container.read(filteredBalanceProvider), closeTo(3.5, 1e-9),
        reason: 'level 6 (net balance) should equal incoming-only total once outgoing is filtered out');

    // Narrow further with a minimum value — only the 2.0 ETH transaction remains.
    container.read(transactionFilterProvider.notifier).setMinValueEth(1.5);

    expect(container.read(filteredTransactionsProvider).length, 1);
    expect(container.read(filteredTransactionsProvider).single.hash, '0xin2');
    expect(container.read(directionTotalsProvider)[TransactionDirection.incoming], closeTo(2.0, 1e-9));
    expect(container.read(filteredBalanceProvider), closeTo(2.0, 1e-9));
  });
}
