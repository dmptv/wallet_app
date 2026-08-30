import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'models/transaction.dart';

// Public Blockscout instance (Ethereum mainnet), no API key required.
const _blockscoutBaseUrl = 'https://eth.blockscout.com/api/v2';

// A well-known, publicly active address, used as the default "watched
// wallet" so the transaction list has real, non-trivial history to show.
final watchedAddressProvider = Provider<String>((ref) {
  return '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045';
});

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
    final uri = Uri.parse('$_blockscoutBaseUrl/addresses/$address/transactions');
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
