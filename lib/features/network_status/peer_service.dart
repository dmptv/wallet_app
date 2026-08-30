import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/peer.dart';

final peerServiceProvider = Provider<PeerService>((ref) {
  return SimulatedPeerService();
});

abstract class PeerService {
  Future<List<Peer>> fetchPeers();
}

// There is no real peer-to-peer backend behind this screen — network
// topology data like this normally comes from a node you run yourself, not
// a public API. Latency and liveness are simulated locally so the screen
// has real, moving traffic to observe and profile.
class SimulatedPeerService implements PeerService {
  // Approximate real-world coordinates for well-known data-center regions.
  static const _regions = [
    ('Frankfurt', 50.11, 8.68),
    ('Singapore', 1.35, 103.82),
    ('Virginia', 37.54, -77.43),
    ('São Paulo', -23.55, -46.63),
    ('Tokyo', 35.68, 139.69),
    ('Sydney', -33.87, 151.21),
    ('London', 51.51, -0.13),
    ('Mumbai', 19.08, 72.88),
  ];

  final _random = Random();

  @override
  Future<List<Peer>> fetchPeers() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return List.generate(60, (i) {
      final (region, lat, lon) = _regions[i % _regions.length];
      // Jitter each peer's position slightly around its region so the map
      // shows a cluster of dots rather than a single overlapping pin.
      final jitteredLat = lat + (_random.nextDouble() - 0.5) * 4;
      final jitteredLon = lon + (_random.nextDouble() - 0.5) * 4;

      return Peer(
        id: 'peer_$i',
        region: region,
        latitude: jitteredLat,
        longitude: jitteredLon,
        latencyMs: 20 + _random.nextInt(280),
        isActive: _random.nextDouble() > 0.12,
      );
    });
  }
}
