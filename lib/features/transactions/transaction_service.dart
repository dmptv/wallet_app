import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../wallet_config.dart';
import 'models/transaction.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return BlockscoutTransactionService(client: http.Client());
});

abstract class TransactionService {
  Future<List<Transaction>> fetchTransactions(String address);
}

class BlockscoutApiException implements Exception {
  final int statusCode;
  final String message;

  BlockscoutApiException(this.statusCode, this.message);

  @override
  String toString() => 'BlockscoutApiException($statusCode): $message';
}

class BlockscoutTransactionService implements TransactionService {
  final http.Client client;

  BlockscoutTransactionService({required this.client});

  @override
  Future<List<Transaction>> fetchTransactions(String address) async {
    final uri = Uri.parse('$blockscoutBaseUrl/addresses/$address/transactions');
    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw BlockscoutApiException(response.statusCode, response.body);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>;

    return items
        .cast<Map<String, dynamic>>()
        .map((json) => Transaction.fromBlockscoutJson(json, watchedAddress: address))
        .toList();
  }
}
