import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart'; // 👉 pakai baseUrl yang sama

class EmissionApi {
  // Ambil baseUrl dari ApiService
  static String get _baseUrl => ApiService.baseUrl;

  /// Ambil total emisi bulan tertentu (default: bulan & tahun sekarang)
  static Future<double> getMonthlyTotal({int? year, int? month}) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;

    final uri = Uri.parse('$_baseUrl/emissions/monthly?year=$y&month=$m');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['status'] == true) {
        final num total = data['total_emission_kg'] ?? 0;
        return total.toDouble();
      }
    }

    throw Exception('Gagal mengambil total emisi bulan ini');
  }
}
