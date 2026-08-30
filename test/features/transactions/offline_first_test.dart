import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_app/features/transactions/models/transaction.dart';
import 'package:wallet_app/features/transactions/transaction_cache.dart';
import 'package:wallet_app/features/transactions/transaction_providers.dart';
import 'package:wallet_app/features/transactions/transaction_service.dart';
import 'package:wallet_app/wallet_config.dart';

const _address = '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045';

final _cachedTransaction = Transaction(
  hash: '0xcached',
  from: '0xabc',
  to: _address,
  valueWei: BigInt.from(1000000000000000000),
  gasUsed: 21000,
  status: 'ok',
  timestamp: DateTime.utc(2026, 1, 1),
  direction: TransactionDirection.incoming,
);

class FakeTransactionCache implements TransactionCache {
  final Map<String, List<Transaction>> _store = {};

  @override
  Future<List<Transaction>?> load(String address) async => _store[address.toLowerCase()];

  @override
  Future<void> save(String address, List<Transaction> transactions) async {
    _store[address.toLowerCase()] = transactions;
  }
}

class FailingTransactionService implements TransactionService {
  @override
  Future<List<Transaction>> fetchTransactions(String address) async {
    throw Exception('network unreachable');
  }
}

void main() {
  test('cached data shows immediately and stays when the background refresh fails offline', () async {
    final cache = FakeTransactionCache();
    await cache.save(_address, [_cachedTransaction]);

    final container = ProviderContainer(overrides: [
      watchedAddressProvider.overrideWithValue(_address),
      transactionCacheProvider.overrideWithValue(cache),
      transactionServiceProvider.overrideWithValue(FailingTransactionService()),
    ]);
    addTearDown(container.dispose);

    container.listen(rawTransactionsProvider, (_, _) {});
    container.listen(transactionSyncStatusProvider, (_, _) {});

    final initial = await container.read(rawTransactionsProvider.future);
    expect(initial, [_cachedTransaction], reason: 'cached data should be returned immediately, before any network call');

    // Let the background refresh (kicked off via Future.microtask) run and fail.
    await Future.delayed(const Duration(milliseconds: 50));

    expect(
      container.read(transactionSyncStatusProvider),
      TransactionSyncStatus.offline,
      reason: 'a failed background refresh should flip sync status to offline',
    );
    expect(
      container.read(rawTransactionsProvider).value,
      [_cachedTransaction],
      reason: 'cached data must stay on screen instead of being replaced by an error state',
    );
  });
}
