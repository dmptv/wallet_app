enum TransactionType { income, expense }

class Transaction {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String merchant;
  final TransactionType type;

  const Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.merchant,
    required this.type,
  });
}
