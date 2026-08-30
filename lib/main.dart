import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_app/counter_notifier.dart';
import 'package:wallet_app/balance_notifier.dart';
import 'package:wallet_app/home_screen.dart';
import 'package:wallet_app/core/logging_observer.dart';


final counterProvider = NotifierProvider<CounterNotifier, int>(CounterNotifier.new);

final balanceProvider = AsyncNotifierProvider<BalanceNotifier, double>(BalanceNotifier.new, isAutoDispose: true); // Set isAutoDispose to false to keep the state alive


void main() {
  runApp(
    ProviderScope(
      observers: [LoggingObserver()],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomeScreen(),
    );
  }
}