import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

final balanceServiceProvider = Provider<BalanceService>((ref) {
  return InMemoryBalanceService();
});

abstract class BalanceService { Future<double> fetchBalance(); }

class InMemoryBalanceService implements BalanceService {
  
  @override
  Future<double> fetchBalance() async {
    await Future.delayed(const Duration(seconds: 2));
    return 3333.0 + Random().nextInt(100); // Return a random balance between 1000 and 2000
  }
}