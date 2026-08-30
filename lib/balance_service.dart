import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'wallet_config.dart';

final balanceServiceProvider = Provider<BalanceService>((ref) {
  return BlockscoutBalanceService(client: http.Client());
});

abstract class BalanceService {
  Future<double> fetchBalance(String address);
}

class BlockscoutBalanceService implements BalanceService {
  final http.Client client;

  BlockscoutBalanceService({required this.client});

  @override
  Future<double> fetchBalance(String address) async {
    final uri = Uri.parse('$blockscoutBaseUrl/addresses/$address');
    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load balance: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final balanceWei = BigInt.parse(body['coin_balance'] as String? ?? '0');
    return balanceWei.toDouble() / 1e18;
  }
}
