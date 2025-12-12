import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'detail_riwayat_page.dart';
import 'models/trip_history.dart';
import 'services/history_service.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final HistoryService _service = HistoryService();
  late Future<List<TripHistory>> _futureTrips;

  @override
  void initState() {
    super.initState();
    _futureTrips = _service.fetchTrips();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureTrips = _service.fetchTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Perjalanan"),
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<TripHistory>>(
          future: _futureTrips,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Gagal memuat riwayat.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ),
                ],
              );
            }

            final trips = snapshot.data ?? [];

            if (trips.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Belum ada riwayat perjalanan.\n'
                      'Mulai perjalanan dari menu Hitung Emisi 😊',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final t = trips[index];

                final tanggal = _formatDate(t.startedAt);
                final jamRange = _formatTimeRange(t.startedAt, t.endedAt);
                final durasi = _formatDuration(t.duration);

                // Map dikirim ke DetailRiwayatPage biar kompatibel
                final dataForDetail = {
                  'id': t.id,
                  'kendaraan': t.vehicleSummary,
                  'jarak': '${t.distanceKm.toStringAsFixed(2)} Km',
                  'waktu': durasi,
                  'co2': t.emissionKg.toStringAsFixed(2),
                  'tanggal': tanggal,
                  'jam': jamRange,
                  'startedAt': t.startedAt?.toIso8601String(),
                  'endedAt': t.endedAt?.toIso8601String(),

                  // ===== koordinat rute (opsional) =====
                  if (t.startLat != null && t.startLng != null)
                    'start': [t.startLat, t.startLng],
                  if (t.endLat != null && t.endLng != null)
                    'end': [t.endLat, t.endLng],
                };

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailRiwayatPage(data: dataForDetail),
                      ),
                    );
                  },
                  child: _buildHistoryCard(t, tanggal, jamRange, durasi),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ================== WIDGET KARTU RIWAYAT ==================

  Widget _buildHistoryCard(
    TripHistory trip,
    String tanggal,
    String jamRange,
    String durasi,
  ) {
    final iconData = _vehicleIcon(trip.vehicleSummary);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // kendaraan + emisi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          trip.vehicleSummary,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Emisi',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                          Text(
                            '${trip.emissionKg.toStringAsFixed(2)} kg CO\u2082',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // jarak · waktu
                  Text(
                    '${trip.distanceKm.toStringAsFixed(2)} km · $durasi',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // tanggal, jam
                  Text(
                    '$tanggal, $jamRange',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
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

  // ================== HELPER FORMAT & ICON ==================

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final formatter = DateFormat('d MMMM yyyy'); // contoh: 30 November 2025
    return formatter.format(dt);
  }

  String _formatTimeRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '-';
    final fmt = DateFormat('HH:mm');
    return '${fmt.format(start)} – ${fmt.format(end)} WIB';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours} j ${d.inMinutes.remainder(60)} m';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes} m ${d.inSeconds.remainder(60)} d';
    } else {
      return '${d.inSeconds} detik';
    }
  }

  IconData _vehicleIcon(String summary) {
    final lower = summary.toLowerCase();
    if (lower.contains('motor')) {
      return Icons.two_wheeler;
    } else if (lower.contains('bus')) {
      return Icons.directions_bus;
    } else if (lower.contains('listrik')) {
      return Icons.electric_car;
    } else {
      return Icons.directions_car;
    }
  }
}
