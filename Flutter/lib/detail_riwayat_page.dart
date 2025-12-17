import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DetailRiwayatPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailRiwayatPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Coba ambil list route_points dulu (kalau ada)
    final List<LatLng> routePoints =
        _routeFromData(data['route_points'] ?? data['routePoints']);

    // Kalau routePoints ada, pakai titik pertama & terakhir sebagai start/end
    LatLng? startPoint;
    LatLng? endPoint;

    if (routePoints.isNotEmpty) {
      startPoint = routePoints.first;
      endPoint = routePoints.last;
    } else {
      // fallback ke data lama: data['start'] & data['end'] (mis. [lat, lng])
      startPoint = _latLngFromData(data['start']);
      endPoint = _latLngFromData(data['end']);
    }

    // Polyline yang akan digambar:
    final List<LatLng> polylinePoints = routePoints.isNotEmpty
        ? routePoints
        : (startPoint != null && endPoint != null
            ? [startPoint, endPoint]
            : <LatLng>[]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Perjalanan'),
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= MAP / PLACEHOLDER =================
            if (startPoint != null && endPoint != null)
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: endPoint, // fokus ke titik akhir / rute
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        // pakai OSM default; kalau kamu pakai MapTiler, sesuaikan di sini
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: startPoint,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 32,
                            ),
                          ),
                          Marker(
                            point: endPoint,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.flag,
                              color: Colors.red,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      if (polylinePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              strokeWidth: 4,
                              color: Colors.green,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text(
                    'Peta perjalanan belum tersedia untuk riwayat ini.\n'
                    'Data rute akan ditampilkan jika koordinat perjalanan disimpan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ================= DETAIL PERJALANAN =================
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kendaraan
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_car, // atau bisa diimprovisasi dari text
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['kendaraan'] ?? '-',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Tanggal & jam
                  _infoRow(
                    icon: Icons.calendar_today,
                    label: 'Tanggal',
                    value: data['tanggal'] ?? '-',
                  ),
                  const SizedBox(height: 6),
                  _infoRow(
                    icon: Icons.access_time,
                    label: 'Waktu',
                    value: data['jam'] ?? '-',
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Jarak & durasi
                  _infoRow(
                    icon: Icons.route,
                    label: 'Jarak tempuh',
                    value: data['jarak'] ?? '-',
                  ),
                  const SizedBox(height: 6),
                  _infoRow(
                    icon: Icons.timer,
                    label: 'Durasi',
                    value: data['waktu'] ?? '-',
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Emisi
                  const Text(
                    'Total emisi perjalanan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        (data['co2'] ?? '0.00').toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Text(
                          'kg CO\u2082',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Emisi dihitung dari jarak tempuh dan jenis kendaraan '
                    'yang digunakan pada perjalanan ini.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER ====================

  /// Expect: [lat, lng]
  static LatLng? _latLngFromData(dynamic raw) {
    if (raw is List && raw.length == 2) {
      final lat = (raw[0] as num?)?.toDouble();
      final lng = (raw[1] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  /// Parse route_points dari berbagai bentuk:
  /// - List<Map<String, dynamic>> dengan key 'lat','lng'
  /// - List<List<num>> berisi [lat, lng]
  static List<LatLng> _routeFromData(dynamic raw) {
    final List<LatLng> result = [];
    if (raw is List) {
      for (final p in raw) {
        if (p is Map) {
          final lat = (p['lat'] as num?)?.toDouble();
          final lng = (p['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            result.add(LatLng(lat, lng));
          }
        } else if (p is List && p.length == 2) {
          final lat = (p[0] as num?)?.toDouble();
          final lng = (p[1] as num?)?.toDouble();
          if (lat != null && lng != null) {
            result.add(LatLng(lat, lng));
          }
        }
      }
    }
    return result;
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF22C55E)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
