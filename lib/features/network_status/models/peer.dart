class Peer {
  final String id;
  final String region;
  final double latitude;
  final double longitude;
  final int latencyMs;
  final bool isActive;

  const Peer({
    required this.id,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.latencyMs,
    required this.isActive,
  });
}
