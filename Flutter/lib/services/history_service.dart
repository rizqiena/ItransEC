import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/trip_history.dart';

class HistoryService {
  // sesuaikan dengan setting mu
  static const String _baseUrl = 'http://10.0.2.2:8000/api';

  Future<List<TripHistory>> fetchTrips() async {
    final response = await http.get(Uri.parse('$_baseUrl/trips'));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil riwayat (code ${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => TripHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTrip({
    required String vehicleSummary,
    required double distanceKm,
    required double emissionKg,
    required Duration duration,
    DateTime? startedAt,
    DateTime? endedAt,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    List<Map<String, dynamic>>? routePoints, // <--- BARU
  }) async {
    final body = {
      'vehicle_summary': vehicleSummary,
      'distance_km': distanceKm,
      'emission_kg': emissionKg,
      'duration_seconds': duration.inSeconds,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'route_points': routePoints, // <--- BARU: list {lat,lng} atau null
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/trips'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Gagal menyimpan riwayat (code ${response.statusCode})');
    }
  }
}
