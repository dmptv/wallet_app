enum TransactionDirection { incoming, outgoing }

class Transaction {
  final String hash;
  final String from;
  final String to;
  final BigInt valueWei;
  final int gasUsed;
  final String status;
  final DateTime timestamp;
  final TransactionDirection direction;

  const Transaction({
    required this.hash,
    required this.from,
    required this.to,
    required this.valueWei,
    required this.gasUsed,
    required this.status,
    required this.timestamp,
    required this.direction,
  });

  double get valueEth => valueWei.toDouble() / 1e18;

  factory Transaction.fromBlockscoutJson(Map<String, dynamic> json, {required String watchedAddress}) {
    final from = (json['from']?['hash'] as String?) ?? '';
    final to = (json['to']?['hash'] as String?) ?? '';

    return Transaction(
      hash: json['hash'] as String,
      from: from,
      to: to,
      valueWei: BigInt.parse(json['value'] as String? ?? '0'),
      gasUsed: int.tryParse(json['gas_used'] as String? ?? '0') ?? 0,
      status: json['status'] as String? ?? 'unknown',
      timestamp: DateTime.parse(json['timestamp'] as String),
      direction: to.toLowerCase() == watchedAddress.toLowerCase()
          ? TransactionDirection.incoming
          : TransactionDirection.outgoing,
    );
  }
}
