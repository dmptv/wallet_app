import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/network_status/network_status_screen.dart';
import 'features/transactions/transaction_screen.dart';
import 'main.dart';
import 'wallet_config.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);
    final address = ref.watch(watchedAddressProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _BalanceCard(balance: balance),
                    const SizedBox(height: 24),
                    _ActionRow(
                      onHistory: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TransactionScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _NetworkStatusBar(
              address: address,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NetworkStatusScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text('Wallet', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final AsyncValue<double> balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Total balance', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          balance.when(
            data: (value) => Text(
              '${value.toStringAsFixed(5)} ETH',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => const Text(
              'Failed to load balance',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onHistory;

  const _ActionRow({required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(icon: Icons.arrow_downward, label: 'Receive', isEnabled: false, onTap: () {}),
        ),
        Expanded(
          child: _ActionButton(icon: Icons.send, label: 'Send', isEnabled: false, onTap: () {}),
        ),
        Expanded(
          child: _ActionButton(icon: Icons.qr_code_scanner, label: 'Scan QR', isEnabled: false, onTap: () {}),
        ),
        Expanded(
          child: _ActionButton(icon: Icons.history, label: 'History', isEnabled: true, onTap: onHistory),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        IconButton(
          onPressed: isEnabled ? onTap : null,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: isEnabled ? scheme.primary : scheme.surfaceContainerHighest,
            foregroundColor: isEnabled ? scheme.onPrimary : scheme.onSurfaceVariant,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _NetworkStatusBar extends StatelessWidget {
  final String address;
  final VoidCallback onTap;

  const _NetworkStatusBar({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final shortAddress = '${address.substring(0, 6)}...${address.substring(address.length - 4)}';

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            const Icon(Icons.circle, size: 10, color: Colors.green),
            const SizedBox(width: 8),
            Text(shortAddress, style: const TextStyle(fontSize: 13)),
            const Spacer(),
            const Text('Network status', style: TextStyle(fontSize: 13)),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}
