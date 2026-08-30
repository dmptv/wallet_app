import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'models/peer.dart';
import 'network_status_providers.dart';

class NetworkStatusScreen extends StatelessWidget {
  const NetworkStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Status')),
      body: const Column(
        children: [
          NetworkStatusSummaryCard(),
          NetworkMapView(),
          LivenessChartView(),
          Expanded(child: PeerListView()),
        ],
      ),
    );
  }
}

// Reads only the two scalar aggregates via select — does not rebuild on
// every raw peer refresh, only when the derived numbers actually change.
class NetworkStatusSummaryCard extends ConsumerWidget {
  const NetworkStatusSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = ref.watch(activePeerCountProvider);
    final avgLatency = ref.watch(averageLatencyProvider);
    debugPrint('NetworkStatusSummaryCard rebuild');

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$activeCount active peers', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${avgLatency.toStringAsFixed(0)} ms avg'),
          ],
        ),
      ),
    );
  }
}

class NetworkMapView extends ConsumerWidget {
  const NetworkMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peers = ref.watch(activePeersProvider);
    debugPrint('NetworkMapView rebuild: ${peers.length} pins');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AspectRatio(
        aspectRatio: 2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFFEFEFEF)),
              SvgPicture.asset('assets/maps/world_map.svg', fit: BoxFit.fill),
              CustomPaint(painter: _PeerPinsPainter(peers)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeerPinsPainter extends CustomPainter {
  final List<Peer> peers;

  _PeerPinsPainter(this.peers);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.redAccent.withValues(alpha: 0.85);
    for (final peer in peers) {
      final x = (peer.longitude + 180) / 360 * size.width;
      final y = (90 - peer.latitude) / 180 * size.height;
      canvas.drawCircle(Offset(x, y), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PeerPinsPainter oldDelegate) => oldDelegate.peers != peers;
}

class LivenessChartView extends ConsumerWidget {
  const LivenessChartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(livenessHistoryProvider);
    debugPrint('LivenessChartView rebuild: ${history.length} samples');

    if (history.isEmpty) {
      return const SizedBox(height: 80);
    }

    final maxValue = history.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final value in history)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: (value / maxValue) * 80,
                  color: Colors.blueAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PeerListView extends ConsumerWidget {
  const PeerListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawState = ref.watch(rawPeersProvider);
    debugPrint('PeerListView rebuild');

    return rawState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Failed to load peers: $error')),
      data: (peers) => ListView.builder(
        itemCount: peers.length,
        itemBuilder: (context, index) {
          final p = peers[index];
          return ListTile(
            leading: Icon(Icons.circle, size: 10, color: p.isActive ? Colors.green : Colors.grey),
            title: Text(p.region),
            subtitle: Text(p.id),
            trailing: Text('${p.latencyMs} ms'),
          );
        },
      ),
    );
  }
}
