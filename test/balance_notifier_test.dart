
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_app/balance_service.dart';
import 'package:wallet_app/balance_notifier.dart';
import 'package:wallet_app/main.dart';

void main() {
  test('два одновременных refresh дают один запрос', () async {
    final spy = SpyBalanceService(delay: const Duration(seconds: 1));
    final container = ProviderContainer(overrides: [
      balanceServiceProvider.overrideWithValue(spy), pollIntervalProvider.overrideWithValue(const Duration(hours: 1))],);
    container.listen(balanceProvider, (_, _) {});

    await container.read(balanceProvider.future);
    final callsAfterInitialLoad = spy.callCount;

    final future1 = container.read(balanceProvider.notifier).refresh();
    final future2 = container.read(balanceProvider.notifier).refresh();
    await Future.wait([future1, future2]);

    expect(spy.callCount - callsAfterInitialLoad, 1, reason: 'два конкурентных refresh должны схлопнуться в один запрос');

    addTearDown(container.dispose);
  });

   test('таймер перестаёт стрелять после dispose', () async {
    final spy = SpyBalanceService();
    final container = ProviderContainer(overrides: [
      balanceServiceProvider.overrideWithValue(spy),
      pollIntervalProvider.overrideWithValue(const Duration(milliseconds: 50))
      ],);
    final sub = container.listen(balanceProvider, (_, _) {});

    await container.read(balanceProvider.future);
    final callsAfterInitialLoad = spy.callCount;
    sub.close(); // Dispose the provider

    await Future.delayed(const Duration(milliseconds: 50));

    expect(spy.callCount, callsAfterInitialLoad, reason: 'таймер перестаёт стрелять после dispose');

    addTearDown(container.dispose);
  });
}

class SpyBalanceService implements BalanceService {
  int callCount = 0;
  final Duration delay;
  SpyBalanceService({this.delay = Duration.zero});

  @override
  Future<double> fetchBalance() async {
    callCount++;
    await Future.delayed(delay);
    return 42.0; // Return a fixed balance for testing
  }
}




