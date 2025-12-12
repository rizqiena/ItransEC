import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_helper.dart';
import 'live_tracking_page.dart';
import 'services/history_service.dart';

/// ===== ENUM UNTUK DETAIL KENDARAAN =====

// Motor
enum EngineClass { small, medium, large } // <=125, 126-250, >250 cc
enum FuelRon { ron90, ron92, ron95, ron98 }

// Mobil bensin
enum CarClass { small, medium, large } // <=1300, 1301-1800, >1800

// Bus
enum BusSize { small, medium, large } // <20, 25-35, 40-60 kursi
enum BusFuel { diesel, gas, electric } // solar, CNG/LNG, listrik

// Mobil listrik
enum EvBatteryClass { small, medium, large } // <40, 40-70, >70 kWh
enum EvPowerSource { pln, solarPanel, fastCharging }

class HitungEmisiPage extends StatefulWidget {
  const HitungEmisiPage({super.key});

  @override
  State<HitungEmisiPage> createState() => _HitungEmisiPageState();
}

class _HitungEmisiPageState extends State<HitungEmisiPage> {
  String? _selectedVehicle; // Mobil / Bus / Motor / Mobil listrik

  // Detail pilihan kendaraan
  EngineClass? _selectedEngineClass;
  FuelRon? _selectedMotorRon;

  CarClass? _selectedCarClass;
  FuelRon? _selectedCarRon;

  BusSize? _selectedBusSize;
  BusFuel? _selectedBusFuel;

  EvBatteryClass? _selectedEvBattery;
  EvPowerSource? _selectedEvPower;

  bool _isTracking = false;
  DateTime? _startTime;
  DateTime? _endTime;

  // hasil dari live tracking
  double? _lastDistanceKm;
  Duration? _lastDuration;

  // hasil perhitungan emisi
  double? _lastEmissionKg;

  // koordinat perjalanan terakhir
  double? _startLat;
  double? _startLng;
  double? _endLat;
  double? _endLng;

  // titik rute lengkap untuk dikirim ke backend
  List<Map<String, dynamic>>? _routePoints;

  // helper: apakah sudah ada hasil perjalanan
  bool get _hasResult => _lastDistanceKm != null && _lastDuration != null;

  // service untuk simpan riwayat ke backend
  final HistoryService _historyService = HistoryService();

  // ===== KEY SHARED PREFERENCES (SAMA DENGAN PAYMENT PAGE) =====
  static const _kSavedTotalEmisi = 'total_emisi';
  static const _kLastSessionEmisi = 'last_session_emisi';
  static const _kSavedHargaKg = 'saved_harga_kg';
  static const _kSavedJarak = 'saved_jarak';
  static const _kSavedVehicle = 'saved_vehicle';
  static const _kSavedKapasitas = 'saved_kapasitas';
  static const _kSavedBahanBakar = 'saved_bahan_bakar';
  static const _kSavedFuelType = 'saved_fueltype';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Pilih jenis kendaraan kamu",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // ===== GRID PILIHAN KENDARAAN =====
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.85,
                children: [
                  _buildVehicleCard(
                    "Mobil",
                    "assets/splash/icons/mobil.png",
                    Icons.directions_car,
                  ),
                  _buildVehicleCard(
                    "Bus",
                    "assets/splash/icons/bus.png",
                    Icons.directions_bus,
                  ),
                  _buildVehicleCard(
                    "Motor",
                    "assets/splash/icons/motor.png",
                    Icons.two_wheeler,
                  ),
                  _buildVehicleCard(
                    "Mobil listrik",
                    "assets/splash/icons/mobil_listrik.png",
                    Icons.electric_car,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ===== DETAIL SESUAI KENDARAAN YANG DIPILIH =====
              if (_selectedVehicle != null) ...[
                const Divider(height: 32),
                _buildVehicleDetailSection(),
                const SizedBox(height: 24),
              ],

              // ===== TOMBOL START =====
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isTracking ? null : _onStartPressed,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    _hasResult ? 'Mulai perjalanan baru' : 'Start perjalanan',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Teks status hanya muncul saat tracking sedang berlangsung
              if (_isTracking)
                Center(
                  child: Text(
                    _buildStatusText(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // ===== CARD INFO / RINGKASAN DI BAGIAN BAWAH =====
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ================== CARD BAWAH YANG BERUBAH-UBAH ==================
  Widget _buildInfoCard() {
    const title = "Kalkulator Emisi Kendaraan";
    const subtitle = "Pantau jejak karbon dari perjalananmu";

    final bool hasResult = _hasResult;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ikon + title + subtitle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/splash/icons/logo_android12.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.eco,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
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

          const SizedBox(height: 12),

          if (_isTracking) ...[
            const Text(
              "Perjalanan sedang berlangsung di halaman live tracking. "
                  "Kembali ke sini setelah menekan Finish di sana.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ] else if (hasResult) ...[
            const Text(
              "Perjalanan selesai.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),

            // Durasi dengan ikon jam
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Color(0xFF4CAF50),
                ),
                const SizedBox(width: 6),
                Text(
                  "Perkiraan durasi: ${_formatDuration(_lastDuration!)}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Jarak dengan ikon rute
            Row(
              children: [
                const Icon(
                  Icons.route,
                  size: 18,
                  color: Color(0xFF4CAF50),
                ),
                const SizedBox(width: 6),
                Text(
                  "Perkiraan jarak: ${_lastDistanceKm!.toStringAsFixed(2)} km.",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 8),

            const Text(
              "Total emisi perjalanan ini",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),

            // Angka emisi
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _lastEmissionKg != null
                      ? _lastEmissionKg!.toStringAsFixed(2)
                      : "–",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    "kg CO\u2082",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            const Text(
              "Nilai emisi perjalanan ini akan dihitung dari jarak tempuh dan "
                  "detail kendaraan yang kamu pilih, lalu ikut terakumulasi dalam "
                  "total emisi bulan ini.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ] else ...[
            const Text(
              "Pilih jenis kendaraan untuk menghitung emisi perjalananmu. "
                  "Setelah itu, lengkapi detail kendaraan dan mulai perjalanan "
                  "dengan tombol Start.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================== GRID KARTU KENDARAAN ==================
  Widget _buildVehicleCard(
      String title,
      String imagePath,
      IconData fallbackIcon,
      ) {
    final bool isSelected = _selectedVehicle == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicle = title;

          // reset semua detail ketika ganti kendaraan
          _selectedEngineClass = null;
          _selectedMotorRon = null;
          _selectedCarClass = null;
          _selectedCarRon = null;
          _selectedBusSize = null;
          _selectedBusFuel = null;
          _selectedEvBattery = null;
          _selectedEvPower = null;

          _lastDistanceKm = null;
          _lastDuration = null;
          _lastEmissionKg = null;
          _startTime = null;
          _endTime = null;

          // reset koordinat & rute
          _startLat = null;
          _startLng = null;
          _endLat = null;
          _endLng = null;
          _routePoints = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  fallbackIcon,
                  size: 80,
                  color: const Color(0xFF4CAF50),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== DETAIL SESUAI KENDARAAN ==================
  Widget _buildVehicleDetailSection() {
    switch (_selectedVehicle) {
      case "Motor":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kapasitas mesin motor",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _OptionChip(
                  label: "<= 125 cc",
                  isSelected: _selectedEngineClass == EngineClass.small,
                  onTap: () {
                    setState(() => _selectedEngineClass = EngineClass.small);
                  },
                ),
                _OptionChip(
                  label: "126–250 cc",
                  isSelected: _selectedEngineClass == EngineClass.medium,
                  onTap: () {
                    setState(() => _selectedEngineClass = EngineClass.medium);
                  },
                ),
                _OptionChip(
                  label: "> 250 cc",
                  isSelected: _selectedEngineClass == EngineClass.large,
                  onTap: () {
                    setState(() => _selectedEngineClass = EngineClass.large);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Angka oktan (RON)",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final ron in FuelRon.values)
                  _OptionChip(
                    label: _ronLabel(ron),
                    isSelected: _selectedMotorRon == ron,
                    onTap: () {
                      setState(() => _selectedMotorRon = ron);
                    },
                  ),
              ],
            ),
          ],
        );

      case "Mobil":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kapasitas mesin mobil",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _OptionChip(
                  label: "Kecil (<=1300 cc)",
                  isSelected: _selectedCarClass == CarClass.small,
                  onTap: () {
                    setState(() => _selectedCarClass = CarClass.small);
                  },
                ),
                _OptionChip(
                  label: "Sedang (1301–1800)",
                  isSelected: _selectedCarClass == CarClass.medium,
                  onTap: () {
                    setState(() => _selectedCarClass = CarClass.medium);
                  },
                ),
                _OptionChip(
                  label: "Besar (>1800 cc)",
                  isSelected: _selectedCarClass == CarClass.large,
                  onTap: () {
                    setState(() => _selectedCarClass = CarClass.large);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Angka oktan (RON)",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final ron in FuelRon.values)
                  _OptionChip(
                    label: _ronLabel(ron),
                    isSelected: _selectedCarRon == ron,
                    onTap: () {
                      setState(() => _selectedCarRon = ron);
                    },
                  ),
              ],
            ),
          ],
        );

      case "Bus":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ukuran bus",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _OptionChip(
                  label: "Kecil (<20 kursi)",
                  isSelected: _selectedBusSize == BusSize.small,
                  onTap: () {
                    setState(() => _selectedBusSize = BusSize.small);
                  },
                ),
                _OptionChip(
                  label: "Sedang (25–35)",
                  isSelected: _selectedBusSize == BusSize.medium,
                  onTap: () {
                    setState(() => _selectedBusSize = BusSize.medium);
                  },
                ),
                _OptionChip(
                  label: "Besar (40–60)",
                  isSelected: _selectedBusSize == BusSize.large,
                  onTap: () {
                    setState(() => _selectedBusSize = BusSize.large);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Jenis bahan bakar",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _OptionChip(
                  label: "Diesel",
                  isSelected: _selectedBusFuel == BusFuel.diesel,
                  onTap: () {
                    setState(() => _selectedBusFuel = BusFuel.diesel);
                  },
                ),
                _OptionChip(
                  label: "Gas alam",
                  isSelected: _selectedBusFuel == BusFuel.gas,
                  onTap: () {
                    setState(() => _selectedBusFuel = BusFuel.gas);
                  },
                ),
                _OptionChip(
                  label: "Listrik",
                  isSelected: _selectedBusFuel == BusFuel.electric,
                  onTap: () {
                    setState(() => _selectedBusFuel = BusFuel.electric);
                  },
                ),
              ],
            ),
          ],
        );

      case "Mobil listrik":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kapasitas baterai",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _OptionChip(
                  label: "Kecil (<40 kWh)",
                  isSelected: _selectedEvBattery == EvBatteryClass.small,
                  onTap: () {
                    setState(() => _selectedEvBattery = EvBatteryClass.small);
                  },
                ),
                _OptionChip(
                  label: "Sedang (40–70 kWh)",
                  isSelected: _selectedEvBattery == EvBatteryClass.medium,
                  onTap: () {
                    setState(() => _selectedEvBattery = EvBatteryClass.medium);
                  },
                ),
                _OptionChip(
                  label: "Besar (>70 kWh)",
                  isSelected: _selectedEvBattery == EvBatteryClass.large,
                  onTap: () {
                    setState(() => _selectedEvBattery = EvBatteryClass.large);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Sumber daya",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _OptionChip(
                  label: "Listrik PLN",
                  isSelected: _selectedEvPower == EvPowerSource.pln,
                  onTap: () {
                    setState(() => _selectedEvPower = EvPowerSource.pln);
                  },
                ),
                _OptionChip(
                  label: "Solar panel",
                  isSelected: _selectedEvPower == EvPowerSource.solarPanel,
                  onTap: () {
                    setState(() => _selectedEvPower = EvPowerSource.solarPanel);
                  },
                ),
                _OptionChip(
                  label: "Fast charging",
                  isSelected: _selectedEvPower == EvPowerSource.fastCharging,
                  onTap: () {
                    setState(
                            () => _selectedEvPower = EvPowerSource.fastCharging);
                  },
                ),
              ],
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ================== LOGIKA START ==================
  Future<void> _onStartPressed() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis kendaraan dulu sebelum mulai perjalanan.'),
        ),
      );
      return;
    }

    // Pastikan detail kendaraan sudah lengkap
    if (!_isVehicleDetailComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Lengkapi dulu kapasitas mesin/baterai dan jenis BBM.'),
        ),
      );
      return;
    }

    // cek izin lokasi dulu
    final allowed = await LocationHelper.ensureLocationPermission();
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Izin lokasi belum diberikan atau GPS mati. Aktifkan lokasi untuk mulai tracking.'),
        ),
      );
      return;
    }

    final vehicleSummary = _buildVehicleSummary();

    setState(() {
      _isTracking = true;
      _startTime = DateTime.now();
      _endTime = null;
      _lastDistanceKm = null;
      _lastDuration = null;
      _lastEmissionKg = null;

      // reset koordinat & rute sebelum mulai
      _startLat = null;
      _startLng = null;
      _endLat = null;
      _endLng = null;
      _routePoints = null;
    });

    // Pindah ke halaman live tracking dan tunggu hasilnya
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrackingPage(
          vehicleSummary: vehicleSummary,
        ),
      ),
    );

    // ===== SETELAH KEMBALI DARI LIVE TRACKING =====
    setState(() {
      _isTracking = false;

      if (result is Map) {
        _lastDistanceKm = (result['distanceKm'] as num?)?.toDouble();
        final dur = result['duration'];
        if (dur is Duration) {
          _lastDuration = dur;
          _endTime = _startTime?.add(dur);
        } else {
          _endTime = DateTime.now();
        }

        // ambil koordinat dari LiveTrackingPage
        _startLat = (result['startLat'] as num?)?.toDouble();
        _startLng = (result['startLng'] as num?)?.toDouble();
        _endLat = (result['endLat'] as num?)?.toDouble();
        _endLng = (result['endLng'] as num?)?.toDouble();

        // ambil routePoints dari LiveTrackingPage
        final rp = result['routePoints'];
        if (rp is List) {
          _routePoints = rp.cast<Map<String, dynamic>>();
        } else {
          _routePoints = null;
        }

        // === HITUNG EMISI BERDASARKAN JARAK & FAKTOR ===
        final factorGPerKm = _emissionFactorPerKm(); // g CO2 / km
        if (_lastDistanceKm != null && factorGPerKm != null) {
          // konversi gram ke kilogram
          _lastEmissionKg = _lastDistanceKm! * factorGPerKm / 1000.0;
        } else {
          _lastEmissionKg = null;
        }
      }
    });

    // ===== OTOMATIS SIMPAN KE SHARED PREFERENCES =====
    if (_lastDistanceKm != null &&
        _lastDuration != null &&
        _lastEmissionKg != null &&
        _lastEmissionKg! > 0) {
      await _autoSaveEmissionToLocal(vehicleSummary);
    }

    // === SIMPAN KE BACKEND JIKA DATA LENGKAP ===
    if (_lastDistanceKm != null &&
        _lastDuration != null &&
        _lastEmissionKg != null) {
      try {
        await _historyService.saveTrip(
          vehicleSummary: vehicleSummary,
          distanceKm: _lastDistanceKm!,
          emissionKg: _lastEmissionKg!,
          duration: _lastDuration!,
          startedAt: _startTime,
          endedAt: _endTime,
          startLat: _startLat,
          startLng: _startLng,
          endLat: _endLat,
          endLng: _endLng,
          routePoints: _routePoints,
        );
      } catch (e) {
        // Optional: beri tahu user kalau gagal simpan ke server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Perjalanan berhasil dihitung, tapi gagal menyimpan ke server: $e',
            ),
          ),
        );
      }
    }
  }

  // ===== FUNGSI AUTO SAVE KE LOCAL STORAGE =====
  Future<void> _autoSaveEmissionToLocal(String vehicleSummary) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ambil total emisi lama
      final oldTotal = prefs.getDouble(_kSavedTotalEmisi) ?? 0.0;

      // Tambahkan emisi perjalanan ini
      final newTotal = oldTotal + _lastEmissionKg!;

      // Simpan total baru
      await prefs.setDouble(_kSavedTotalEmisi, newTotal);

      // Simpan detail perjalanan terakhir
      await prefs.setDouble(_kLastSessionEmisi, _lastEmissionKg!);
      await prefs.setDouble(_kSavedJarak, _lastDistanceKm!);

      // Simpan detail kendaraan
      if (_selectedVehicle != null) {
        await prefs.setString(_kSavedVehicle, _selectedVehicle!);
      }

      // Simpan kapasitas & bahan bakar berdasarkan jenis kendaraan
      final kapasitas = _getKapasitasString();
      final bahanBakar = _getBahanBakarString();

      if (kapasitas.isNotEmpty) {
        await prefs.setString(_kSavedKapasitas, kapasitas);
      }
      if (bahanBakar.isNotEmpty) {
        await prefs.setString(_kSavedBahanBakar, bahanBakar);
      }

      // Tampilkan notifikasi sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Emisi tersimpan otomatis!\n"
                  "Perjalanan: ${_lastEmissionKg!.toStringAsFixed(3)} kg CO₂\n"
                  "Total akumulasi: ${newTotal.toStringAsFixed(3)} kg CO₂",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      print("✅ AUTO-SAVE: Emisi ${_lastEmissionKg!.toStringAsFixed(3)} kg berhasil disimpan");
      print("✅ TOTAL AKUMULASI: ${newTotal.toStringAsFixed(3)} kg");

    } catch (e) {
      print("❌ Error saat auto-save emisi: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Gagal menyimpan emisi: $e"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ===== HELPER: GET KAPASITAS STRING =====
  String _getKapasitasString() {
    switch (_selectedVehicle) {
      case "Motor":
        switch (_selectedEngineClass) {
          case EngineClass.small:
            return "<=125 cc";
          case EngineClass.medium:
            return "126–250 cc";
          case EngineClass.large:
            return ">250 cc";
          default:
            return "";
        }
      case "Mobil":
        switch (_selectedCarClass) {
          case CarClass.small:
            return "<=1300 cc";
          case CarClass.medium:
            return "1301–1800 cc";
          case CarClass.large:
            return ">1800 cc";
          default:
            return "";
        }
      case "Bus":
        switch (_selectedBusSize) {
          case BusSize.small:
            return "Kecil (<20 kursi)";
          case BusSize.medium:
            return "Sedang (25–35 kursi)";
          case BusSize.large:
            return "Besar (40–60 kursi)";
          default:
            return "";
        }
      case "Mobil listrik":
        switch (_selectedEvBattery) {
          case EvBatteryClass.small:
            return "<40 kWh";
          case EvBatteryClass.medium:
            return "40–70 kWh";
          case EvBatteryClass.large:
            return ">70 kWh";
          default:
            return "";
        }
      default:
        return "";
    }
  }

  // ===== HELPER: GET BAHAN BAKAR STRING =====
  String _getBahanBakarString() {
    switch (_selectedVehicle) {
      case "Motor":
        return _selectedMotorRon != null ? _ronLabel(_selectedMotorRon!) : "";
      case "Mobil":
        return _selectedCarRon != null ? _ronLabel(_selectedCarRon!) : "";
      case "Bus":
        switch (_selectedBusFuel) {
          case BusFuel.diesel:
            return "Diesel";
          case BusFuel.gas:
            return "Gas alam";
          case BusFuel.electric:
            return "Listrik";
          default:
            return "";
        }
      case "Mobil listrik":
        switch (_selectedEvPower) {
          case EvPowerSource.pln:
            return "Listrik PLN";
          case EvPowerSource.solarPanel:
            return "Solar panel";
          case EvPowerSource.fastCharging:
            return "Fast charging";
          default:
            return "";
        }
      default:
        return "";
    }
  }

  bool _isVehicleDetailComplete() {
    switch (_selectedVehicle) {
      case "Motor":
        return _selectedEngineClass != null && _selectedMotorRon != null;
      case "Mobil":
        return _selectedCarClass != null && _selectedCarRon != null;
      case "Bus":
        return _selectedBusSize != null && _selectedBusFuel != null;
      case "Mobil listrik":
        return _selectedEvBattery != null && _selectedEvPower != null;
      default:
        return false;
    }
  }

  // ====== FAKTOR EMISI (g CO2 per km) – sementara & bisa di-adjust ======
  double? _emissionFactorPerKm() {
    switch (_selectedVehicle) {
      case "Motor":
        double base;
        switch (_selectedEngineClass) {
          case EngineClass.small:
            base = 75; // motor kecil
            break;
          case EngineClass.medium:
            base = 90;
            break;
          case EngineClass.large:
            base = 110;
            break;
          default:
            return null;
        }
        // RON lebih tinggi -> sedikit lebih irit
        double ronAdj;
        switch (_selectedMotorRon) {
          case FuelRon.ron90:
            ronAdj = 1.0;
            break;
          case FuelRon.ron92:
            ronAdj = 0.97;
            break;
          case FuelRon.ron95:
            ronAdj = 0.94;
            break;
          case FuelRon.ron98:
            ronAdj = 0.92;
            break;
          default:
            ronAdj = 1.0;
        }
        return base * ronAdj;

      case "Mobil":
        double base;
        switch (_selectedCarClass) {
          case CarClass.small:
            base = 140;
            break;
          case CarClass.medium:
            base = 170;
            break;
          case CarClass.large:
            base = 210;
            break;
          default:
            return null;
        }
        double ronAdj;
        switch (_selectedCarRon) {
          case FuelRon.ron90:
            ronAdj = 1.0;
            break;
          case FuelRon.ron92:
            ronAdj = 0.97;
            break;
          case FuelRon.ron95:
            ronAdj = 0.94;
            break;
          case FuelRon.ron98:
            ronAdj = 0.92;
            break;
          default:
            ronAdj = 1.0;
        }
        return base * ronAdj;

      case "Bus":
        double base;
        switch (_selectedBusSize) {
          case BusSize.small:
            base = 600;
            break;
          case BusSize.medium:
            base = 800;
            break;
          case BusSize.large:
            base = 1000;
            break;
          default:
            return null;
        }
        double fuelAdj;
        switch (_selectedBusFuel) {
          case BusFuel.diesel:
            fuelAdj = 1.0;
            break;
          case BusFuel.gas:
            fuelAdj = 0.85; // gas alam sedikit lebih bersih
            break;
          case BusFuel.electric:
            fuelAdj = 0.1; // listrik: tailpipe 0, tapi listrik PLN masih ada emisi
            break;
          default:
            fuelAdj = 1.0;
        }
        return base * fuelAdj;

      case "Mobil listrik":
        double base;
        switch (_selectedEvPower) {
          case EvPowerSource.pln:
            base = 80; // emisi dari grid PLN per km
            break;
          case EvPowerSource.fastCharging:
            base = 90;
            break;
          case EvPowerSource.solarPanel:
            base = 5; // hampir nol, tapi kita kasih sedikit untuk produksi panel
            break;
          default:
            return 80;
        }
        // kapasitas baterai tidak terlalu ngaruh ke emisi/km, jadi kita biarin sama
        return base;

      default:
        return null;
    }
  }

  String _buildVehicleSummary() {
    switch (_selectedVehicle) {
      case "Motor":
        final cc = () {
          switch (_selectedEngineClass) {
            case EngineClass.small:
              return "<=125 cc";
            case EngineClass.medium:
              return "126–250 cc";
            case EngineClass.large:
              return ">250 cc";
            default:
              return "";
          }
        }();
        final ron =
        _selectedMotorRon != null ? _ronLabel(_selectedMotorRon!) : "";
        return "Motor · $cc · $ron";

      case "Mobil":
        final cc = () {
          switch (_selectedCarClass) {
            case CarClass.small:
              return "<=1300 cc";
            case CarClass.medium:
              return "1301–1800 cc";
            case CarClass.large:
              return ">1800 cc";
            default:
              return "";
          }
        }();
        final ron = _selectedCarRon != null ? _ronLabel(_selectedCarRon!) : "";
        return "Mobil · $cc · $ron";

      case "Bus":
        final size = () {
          switch (_selectedBusSize) {
            case BusSize.small:
              return "Kecil (<20 kursi)";
            case BusSize.medium:
              return "Sedang (25–35 kursi)";
            case BusSize.large:
              return "Besar (40–60 kursi)";
            default:
              return "";
          }
        }();
        final fuel = () {
          switch (_selectedBusFuel) {
            case BusFuel.diesel:
              return "Diesel";
            case BusFuel.gas:
              return "Gas alam";
            case BusFuel.electric:
              return "Listrik";
            default:
              return "";
          }
        }();
        return "Bus · $size · $fuel";

      case "Mobil listrik":
        final bat = () {
          switch (_selectedEvBattery) {
            case EvBatteryClass.small:
              return "<40 kWh";
            case EvBatteryClass.medium:
              return "40–70 kWh";
            case EvBatteryClass.large:
              return ">70 kWh";
            default:
              return "";
          }
        }();
        final src = () {
          switch (_selectedEvPower) {
            case EvPowerSource.pln:
              return "Listrik PLN";
            case EvPowerSource.solarPanel:
              return "Solar panel";
            case EvPowerSource.fastCharging:
              return "Fast charging";
            default:
              return "";
          }
        }();
        return "Mobil listrik · $bat · $src";

      default:
        return _selectedVehicle ?? 'Kendaraan';
    }
  }

  String _buildStatusText() {
    // sekarang hanya dipakai ketika _isTracking == true
    return "Perjalanan sedang berlangsung di halaman live tracking.\n"
        "Silakan kembali setelah menekan Finish di sana.";
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return "${hours}j ${minutes}m ${seconds}d";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}d";
    } else {
      return "${seconds} detik";
    }
  }
}

// ================== WIDGET CHIP KECIL ==================

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF4CAF50).withOpacity(0.15),
    );
  }
}

String _ronLabel(FuelRon ron) {
  switch (ron) {
    case FuelRon.ron90:
      return 'RON 90';
    case FuelRon.ron92:
      return 'RON 92';
    case FuelRon.ron95:
      return 'RON 95';
    case FuelRon.ron98:
      return 'RON 98';
  }
}