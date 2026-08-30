import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transaction_providers.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: const Column(
        children: [
          BalanceSummaryCard(),
          CategoryChipsRow(),
          Expanded(child: TransactionListView()),
        ],
      ),
    );
  }
}

// Reads only the aggregated balance via select — does not rebuild when the
// filter changes categories without changing the total.
class BalanceSummaryCard extends ConsumerWidget {
  const BalanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(filteredBalanceProvider);
    debugPrint('BalanceSummaryCard rebuild: $balance');

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Balance: ${balance.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Reads the stable category list — does not depend on the current filter
// selection, only on raw data, so switching categories never rebuilds it.
class CategoryChipsRow extends ConsumerWidget {
  const CategoryChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(availableCategoriesProvider);
    final selected = ref.watch(
      transactionFilterProvider.select((f) => f.category),
    );
    debugPrint('CategoryChipsRow rebuild');

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) =>
                ref.read(transactionFilterProvider.notifier).setCategory(null),
          ),
          const SizedBox(width: 8),
          for (final category in categories) ...[
            ChoiceChip(
              label: Text(category),
              selected: selected == category,
              onSelected: (_) => ref
                  .read(transactionFilterProvider.notifier)
                  .setCategory(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class TransactionListView extends ConsumerWidget {
  const TransactionListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    debugPrint('TransactionListView rebuild: ${transactions.length} items');

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        return ListTile(
          title: Text(t.merchant),
          subtitle: Text(t.category),
          trailing: Text(t.amount.toStringAsFixed(2)),
        );
      },
    );
  }
}
