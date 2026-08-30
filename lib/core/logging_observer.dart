import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class LoggingObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    debugPrint('[riverpod] ${context.provider.name ?? context.provider.runtimeType}: $previousValue -> $newValue');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[riverpod] ${context.provider.name ?? context.provider.runtimeType} threw $error');
  }
}
