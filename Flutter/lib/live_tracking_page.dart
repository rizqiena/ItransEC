import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'location_helper.dart';

class LiveTrackingPage extends StatefulWidget {
  /// Contoh: "Mobil · <=1300 cc · RON 90"
  final String vehicleSummary;

  const LiveTrackingPage({
    super.key,
    required this.vehicleSummary,
  });

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final MapController _mapCtrl = MapController();
  final Distance _distanceCalc = const Distance();

  final List<LatLng> _routePoints = [];
  double _totalDistanceKm = 0.0;

  DateTime _startTime = DateTime.now();
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  StreamSubscription<Position>? _posSub;

  // Kalau GPS belum dapat lokasi, pakai Batam sebagai fallback
  final LatLng _fallbackCenter = const LatLng(1.1187, 104.0484);

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startTimer();
    _startLocationStream();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  // ---------------- TIMER ----------------

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_startTime);
      });
    });
  }

  // ---------------- LOCATION STREAM ----------------

  Future<void> _startLocationStream() async {
    final allowed = await LocationHelper.ensureLocationPermission();
    if (!allowed) return;

    // posisi awal
    final firstPos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    final firstPoint = LatLng(firstPos.latitude, firstPos.longitude);

    setState(() {
      _routePoints.add(firstPoint);
    });

    _mapCtrl.move(firstPoint, 16);

    // stream update lokasi
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      final newPoint = LatLng(pos.latitude, pos.longitude);

      setState(() {
        if (_routePoints.isNotEmpty) {
          final double deltaMeters =
              _distanceCalc(_routePoints.last, newPoint);
          _totalDistanceKm += deltaMeters / 1000.0;
        }
        _routePoints.add(newPoint);
        _mapCtrl.move(newPoint, _mapCtrl.camera.zoom);
      });
    });
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final center =
        _routePoints.isNotEmpty ? _routePoints.last : _fallbackCenter;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        title: const Text('Perjalanan sedang berlangsung...'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Akhiri perjalanan?'),
                content: const Text(
                    'Kalau keluar sekarang, tracking perjalanan akan dihentikan.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // ================= MAP =================
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=l9VbWpQlaRqLmd2G5eBd',
                userAgentPackageName: 'com.marhabanakbar.i_transec',
              ),
              RichAttributionWidget(
                attributions: const [
                  TextSourceAttribution(
                    '© MapTiler © OpenStreetMap contributors',
                  ),
                ],
              ),
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),
              if (_routePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    // titik awal
                    Marker(
                      point: _routePoints.first,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
                    // posisi saat ini
                    Marker(
                      point: _routePoints.last,
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFF4CAF50),
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ================= TOMBOL MAP (ZOOM + LOKASI) =================
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapCircleButton(
                  icon: Icons.add,
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 8),
                _MapCircleButton(
                  icon: Icons.remove,
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 16),
                _MapCircleButton(
                  icon: Icons.my_location,
                  onTap: _centerOnUser,
                ),
              ],
            ),
          ),

          // ================= BOTTOM CARD =================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan perjalanan',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.vehicleSummary,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.timer,
                          label: 'Durasi',
                          value: _formatDuration(_elapsed),
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.route,
                          label: 'Jarak',
                          value:
                              '${_totalDistanceKm.toStringAsFixed(2)} km',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _onFinishPressed,
                        icon: const Icon(Icons.flag),
                        label: const Text('Finish perjalanan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- ACTION BUTTONS ----------------

  void _zoomIn() {
    final camera = _mapCtrl.camera;
    _mapCtrl.move(camera.center, camera.zoom + 1);
  }

  void _zoomOut() {
    final camera = _mapCtrl.camera;
    _mapCtrl.move(camera.center, camera.zoom - 1);
  }

  void _centerOnUser() {
    final target =
        _routePoints.isNotEmpty ? _routePoints.last : _fallbackCenter;
    _mapCtrl.move(target, 16);
  }

  // Dipanggil saat tombol Finish ditekan
  void _onFinishPressed() {
    final endTime = DateTime.now();

    // SELALU punya start & end (fallback ke Batam kalau tidak ada titik)
    late final LatLng start;
    late final LatLng end;

    if (_routePoints.isNotEmpty) {
      start = _routePoints.first;
      end = _routePoints.last;
    } else {
      start = _fallbackCenter;
      end = _fallbackCenter;
    }

    final result = {
      'distanceKm': _totalDistanceKm,
      'duration': _elapsed,
      'startLat': start.latitude,
      'startLng': start.longitude,
      'endLat': end.latitude,
      'endLng': end.longitude,

      // baru: waktu mulai & selesai (kalau mau dipakai ke backend)
      'startedAt': _startTime,
      'endedAt': endTime,

      // BARU: kirim semua titik rute ke halaman sebelumnya
      'routePoints': _routePoints
          .map((p) => {
                'lat': p.latitude,
                'lng': p.longitude,
              })
          .toList(),
    };

    Navigator.pop(context, result);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) {
      return '${h}j ${m}m ${s}d';
    } else if (m > 0) {
      return '${m}m ${s}d';
    } else {
      return '$s detik';
    }
  }
}

// ================== WIDGET KECIL ==================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 22,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
