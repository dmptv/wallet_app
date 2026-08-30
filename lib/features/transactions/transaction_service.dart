import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/transaction.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return FakeTransactionService();
});

abstract class TransactionService {
  Future<List<Transaction>> fetchTransactions();
}

class FakeTransactionService implements TransactionService {
  static const _categories = [
    'Groceries',
    'Transport',
    'Entertainment',
    'Utilities',
    'Salary',
    'Dining',
    'Health',
  ];

  static const _merchants = [
    'Whole Foods',
    'Uber',
    'Netflix',
    'City Power Co',
    'Acme Corp',
    'Local Cafe',
    'Pharmacy',
  ];

  @override
  Future<List<Transaction>> fetchTransactions() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final random = Random();
    final now = DateTime.now();

    return List.generate(300, (i) {
      final categoryIndex = random.nextInt(_categories.length);
      final isSalary = _categories[categoryIndex] == 'Salary';

      return Transaction(
        id: 'txn_$i',
        amount: isSalary
            ? 2000 + random.nextInt(1000).toDouble()
            : 5 + random.nextInt(300).toDouble(),
        category: _categories[categoryIndex],
        date: now.subtract(Duration(hours: random.nextInt(24 * 90))),
        merchant: _merchants[categoryIndex],
        type: isSalary ? TransactionType.income : TransactionType.expense,
      );
    });
  }
}
