import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/transaction.dart';
import 'transaction_providers.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: const Column(
        children: [
          BalanceSummaryCard(),
          DirectionChipsRow(),
          Expanded(child: TransactionListView()),
        ],
      ),
    );
  }
}

// Reads only the aggregated net balance via select — does not rebuild when
// the filter changes direction without changing the net total.
class BalanceSummaryCard extends ConsumerWidget {
  const BalanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netChange = ref.watch(filteredBalanceProvider);
    debugPrint('BalanceSummaryCard rebuild: $netChange');

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Net change: ${netChange.toStringAsFixed(5)} ETH',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class DirectionChipsRow extends ConsumerWidget {
  const DirectionChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      transactionFilterProvider.select((f) => f.direction),
    );
    debugPrint('DirectionChipsRow rebuild');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) =>
                ref.read(transactionFilterProvider.notifier).setDirection(null),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Incoming'),
            selected: selected == TransactionDirection.incoming,
            onSelected: (_) => ref
                .read(transactionFilterProvider.notifier)
                .setDirection(TransactionDirection.incoming),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Outgoing'),
            selected: selected == TransactionDirection.outgoing,
            onSelected: (_) => ref
                .read(transactionFilterProvider.notifier)
                .setDirection(TransactionDirection.outgoing),
          ),
        ],
      ),
    );
  }
}

class TransactionListView extends ConsumerWidget {
  const TransactionListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawState = ref.watch(rawTransactionsProvider);
    final transactions = ref.watch(filteredTransactionsProvider);
    debugPrint('TransactionListView rebuild: ${transactions.length} items');

    return rawState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Failed to load: $error')),
      data: (_) => ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final t = transactions[index];
          final isIncoming = t.direction == TransactionDirection.incoming;
          return ListTile(
            leading: Icon(
              isIncoming ? Icons.call_received : Icons.call_made,
              color: isIncoming ? Colors.green : Colors.red,
            ),
            title: Text('${t.hash.substring(0, 10)}...'),
            subtitle: Text(isIncoming ? 'from ${_short(t.from)}' : 'to ${_short(t.to)}'),
            trailing: Text('${t.valueEth.toStringAsFixed(5)} ETH'),
          );
        },
      ),
    );
  }

  String _short(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
