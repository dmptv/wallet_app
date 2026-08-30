import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/peer.dart';
import 'peer_service.dart';

final peerPollIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 3));

// Level 1: raw peer snapshot, refreshed on a timer — the real traffic source
// that everything below reacts to.
class RawPeersNotifier extends AsyncNotifier<List<Peer>> {
  @override
  Future<List<Peer>> build() async {
    final timer = Timer.periodic(ref.read(peerPollIntervalProvider), (_) => refresh());
    ref.onDispose(timer.cancel);

    return ref.read(peerServiceProvider).fetchPeers();
  }

  Future<void> refresh() async {
    final peers = await ref.read(peerServiceProvider).fetchPeers();
    if (ref.mounted) {
      state = AsyncValue.data(peers);
    }
  }
}

final rawPeersProvider = AsyncNotifierProvider<RawPeersNotifier, List<Peer>>(RawPeersNotifier.new);

// Level 2: active peers only, derived from level 1.
final activePeersProvider = Provider<List<Peer>>((ref) {
  final peers = ref.watch(rawPeersProvider).value ?? const [];
  return peers.where((p) => p.isActive).toList();
});

// Level 3: scalar aggregates derived from level 2.
final activePeerCountProvider = Provider<int>((ref) {
  return ref.watch(activePeersProvider).length;
});

final averageLatencyProvider = Provider<double>((ref) {
  final active = ref.watch(activePeersProvider);
  if (active.isEmpty) return 0;
  final total = active.fold<int>(0, (sum, p) => sum + p.latencyMs);
  return total / active.length;
});

// Level 4: grouped view derived from level 2.
final peersByRegionProvider = Provider<Map<String, List<Peer>>>((ref) {
  final active = ref.watch(activePeersProvider);
  final map = <String, List<Peer>>{};
  for (final p in active) {
    map.putIfAbsent(p.region, () => []).add(p);
  }
  return map;
});

// Level 5: rolling history of level-3 samples — accumulates over time by
// listening to averageLatencyProvider, giving the chart real motion instead
// of a single static value.
class LivenessHistoryNotifier extends Notifier<List<double>> {
  static const _maxSamples = 30;

  @override
  List<double> build() {
    ref.listen(averageLatencyProvider, (previous, next) {
      final updated = [...state, next];
      state = updated.length > _maxSamples
          ? updated.sublist(updated.length - _maxSamples)
          : updated;
    });
    return const [];
  }
}

final livenessHistoryProvider = NotifierProvider<LivenessHistoryNotifier, List<double>>(
  LivenessHistoryNotifier.new,
);
