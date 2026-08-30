import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/transaction.dart';

final transactionCacheProvider = Provider<TransactionCache>((ref) {
  return TransactionCache();
});

class TransactionCache {
  String _keyFor(String address) => 'transaction_cache_${address.toLowerCase()}';

  Future<List<Transaction>?> load(String address) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(address));
    if (raw == null) return null;

    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(Transaction.fromCacheJson).toList();
  }

  Future<void> save(String address, List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(transactions.map((t) => t.toCacheJson()).toList());
    await prefs.setString(_keyFor(address), raw);
  }
}
