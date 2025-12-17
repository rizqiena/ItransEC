class TripHistory {
  final int id;
  final String vehicleSummary;
  final double distanceKm;
  final double emissionKg;
  final Duration duration;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double? startLat;   // <--- baru
  final double? startLng;
  final double? endLat;
  final double? endLng;

  TripHistory({
    required this.id,
    required this.vehicleSummary,
    required this.distanceKm,
    required this.emissionKg,
    required this.duration,
    this.startedAt,
    this.endedAt,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
  });

  factory TripHistory.fromJson(Map<String, dynamic> json) {
    return TripHistory(
      id: json['id'] as int,
      vehicleSummary: json['vehicle_summary'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      emissionKg: (json['emission_kg'] as num).toDouble(),
      duration: Duration(seconds: json['duration_seconds'] as int),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      startLat: (json['start_lat'] as num?)?.toDouble(),
      startLng: (json['start_lng'] as num?)?.toDouble(),
      endLat: (json['end_lat'] as num?)?.toDouble(),
      endLng: (json['end_lng'] as num?)?.toDouble(),
    );
  }
}
