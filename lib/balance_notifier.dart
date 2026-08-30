import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async'; 
import 'balance_service.dart';

final pollIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 5));

// ViewModel for managing balance state
class BalanceNotifier extends AsyncNotifier<double> {
  bool _isRefreshing = false;

  @override
  Future<double> build() async {
    final timer = Timer.periodic(ref.read(pollIntervalProvider), (_) {
      refresh();
    });

    ref.onDispose(() {
      timer.cancel();
      print('BalanceNotifier disposed and timer cancelled');
    });

    return await ref.read(balanceServiceProvider).fetchBalance();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes
    _isRefreshing = true;

    state = const AsyncValue.loading();

    try {
      final newBalance = await ref.read(balanceServiceProvider).fetchBalance();
      if (ref.mounted) {
        state = AsyncValue.data(newBalance);
      }
    } catch (e, st) {
      if (ref.mounted) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isRefreshing = false;
    }
  }
}