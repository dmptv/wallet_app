import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'balance_service.dart';
import 'wallet_config.dart';

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

    final address = ref.read(watchedAddressProvider);
    return await ref.read(balanceServiceProvider).fetchBalance(address);
  }

  Future<void> refresh() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes
    _isRefreshing = true;

    state = const AsyncValue.loading();

    try {
      final address = ref.read(watchedAddressProvider);
      final newBalance = await ref.read(balanceServiceProvider).fetchBalance(address);
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