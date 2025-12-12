import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

// ==== ENUM KENDARAAN & PARAMETER ====

enum VehicleType { motor, mobil, bus, mobilListrik }

// Motor
enum EngineClass { small, medium, large } // <=125, 126-250, >250
enum FuelRon { ron90, ron92, ron95, ron98 }

// Mobil bensin
enum CarClass { small, medium, large } // <=1300, 1301-1800, >1800

// Bus
enum BusSize { small, medium, large } // <20, 25-35, 40-60 kursi
enum BusFuel { diesel, gas, electric } // solar, CNG/LNG, listrik

// EV
enum EvBatteryClass { small, medium, large } // <40, 40-70, >70 kWh
enum EvPowerSource { pln, solarPanel, fastCharging }

// ==== TABEL FAKTOR EMISI (g CO2 / km atau g CO2 / pkm) ====

// Motor (per kendaraan)
const Map<EngineClass, Map<FuelRon, double>> kMotorEmissionFactors = {
  EngineClass.small: {
    FuelRon.ron90: 46,
    FuelRon.ron92: 45,
    FuelRon.ron95: 44,
    FuelRon.ron98: 44,
  },
  EngineClass.medium: {
    FuelRon.ron90: 58,
    FuelRon.ron92: 57,
    FuelRon.ron95: 56,
    FuelRon.ron98: 54,
  },
  EngineClass.large: {
    FuelRon.ron90: 77,
    FuelRon.ron92: 75,
    FuelRon.ron95: 74,
    FuelRon.ron98: 73,
  },
};

// Mobil bensin (per kendaraan)
const Map<CarClass, Map<FuelRon, double>> kCarEmissionFactors = {
  CarClass.small: {
    FuelRon.ron90: 144,
    FuelRon.ron92: 142,
    FuelRon.ron95: 139,
    FuelRon.ron98: 136,
  },
  CarClass.medium: {
    FuelRon.ron90: 165,
    FuelRon.ron92: 162,
    FuelRon.ron95: 159,
    FuelRon.ron98: 156,
  },
  CarClass.large: {
    FuelRon.ron90: 210,
    FuelRon.ron92: 206,
    FuelRon.ron95: 202,
    FuelRon.ron98: 198,
  },
};

// Bus (per penumpang)
const Map<BusSize, Map<BusFuel, double>> kBusEmissionFactors = {
  BusSize.small: {
    BusFuel.diesel: 100,
    BusFuel.gas: 85,
    BusFuel.electric: 0,
  },
  BusSize.medium: {
    BusFuel.diesel: 85,
    BusFuel.gas: 70,
    BusFuel.electric: 0,
  },
  BusSize.large: {
    BusFuel.diesel: 75,
    BusFuel.gas: 60,
    BusFuel.electric: 0,
  },
};

// Mobil listrik (per kendaraan, opsi B)
const Map<EvBatteryClass, Map<EvPowerSource, double>> kEvEmissionFactors = {
  EvBatteryClass.small: {
    EvPowerSource.pln: 101,
    EvPowerSource.fastCharging: 111,
    EvPowerSource.solarPanel: 0,
  },
  EvBatteryClass.medium: {
    EvPowerSource.pln: 122,
    EvPowerSource.fastCharging: 135,
    EvPowerSource.solarPanel: 0,
  },
  EvBatteryClass.large: {
    EvPowerSource.pln: 144,
    EvPowerSource.fastCharging: 158,
    EvPowerSource.solarPanel: 0,
  },
};

// ===================== HALAMAN SIMULASI PERJALANAN =====================

class TripSimWithMapPage extends StatefulWidget {
  const TripSimWithMapPage({super.key});

  @override
  State<TripSimWithMapPage> createState() => _TripSimWithMapPageState();
}

class _TripSimWithMapPageState extends State<TripSimWithMapPage> {
  final MapController _mapCtrl = MapController();

  LatLng? _startPoint;
  LatLng? _endPoint;
  double? _distanceKm;
  List<LatLng> _routePoints = [];

  final LatLng _initialCenter = const LatLng(1.1187, 104.0484); // Batam
  final double _initialZoom = 13;

  bool _isLoadingRoute = false;

  // ==== STATE PILIHAN KENDARAAN ====
  VehicleType? _selectedVehicle;

  // Motor
  EngineClass? _selectedEngineClass;
  FuelRon? _selectedMotorRon;

  // Mobil
  CarClass? _selectedCarClass;
  FuelRon? _selectedCarRon;

  // Bus
  BusSize? _selectedBusSize;
  BusFuel? _selectedBusFuel;

  // Mobil listrik
  EvBatteryClass? _selectedEvBattery;
  EvPowerSource? _selectedEvPower;

  // Hasil emisi total (gram CO2)
  double? _emissionGrams;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // hilangin AppBar hijau, biar clean kayak Hitung Emisi
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ==================== MAP ====================
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: _initialZoom,
                      onTap: (tapPos, latlng) => _onMapTap(latlng),
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
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 4,
                              color: Colors.blue,
                            )
                          ],
                        ),
                      if (_startPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _startPoint!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      if (_endPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _endPoint!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Tombol Reset
                  Positioned(
                    top: 10,
                    left: 10,
                    child: ElevatedButton.icon(
                      onPressed: _resetAll,
                      icon: const Icon(Icons.close),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Tombol Zoom
                  Positioned(
                    right: 12,
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ZoomButton(
                          icon: Icons.add,
                          onTap: () {
                            final camera = _mapCtrl.camera;
                            _mapCtrl.move(camera.center, camera.zoom + 1);
                          },
                        ),
                        const SizedBox(height: 8),
                        _ZoomButton(
                          icon: Icons.remove,
                          onTap: () {
                            final camera = _mapCtrl.camera;
                            _mapCtrl.move(camera.center, camera.zoom - 1);
                          },
                        ),
                      ],
                    ),
                  ),

                  if (_isLoadingRoute)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ==================== PILIH KENDARAAN & DETAIL ====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih jenis kendaraan kamu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _VehicleTypeChip(
                        label: 'Mobil',
                        icon: Icons.directions_car,
                        isSelected: _selectedVehicle == VehicleType.mobil,
                        onTap: () {
                          setState(() {
                            _selectedVehicle = VehicleType.mobil;
                            _selectedCarClass = null;
                            _selectedCarRon = null;
                            _selectedEngineClass = null;
                            _selectedMotorRon = null;
                            _selectedBusSize = null;
                            _selectedBusFuel = null;
                            _selectedEvBattery = null;
                            _selectedEvPower = null;
                          });
                          _updateEmission();
                        },
                      ),
                      _VehicleTypeChip(
                        label: 'Bus',
                        icon: Icons.directions_bus,
                        isSelected: _selectedVehicle == VehicleType.bus,
                        onTap: () {
                          setState(() {
                            _selectedVehicle = VehicleType.bus;
                            _selectedBusSize = null;
                            _selectedBusFuel = null;
                            _selectedEngineClass = null;
                            _selectedMotorRon = null;
                            _selectedCarClass = null;
                            _selectedCarRon = null;
                            _selectedEvBattery = null;
                            _selectedEvPower = null;
                          });
                          _updateEmission();
                        },
                      ),
                      _VehicleTypeChip(
                        label: 'Motor',
                        icon: Icons.two_wheeler,
                        isSelected: _selectedVehicle == VehicleType.motor,
                        onTap: () {
                          setState(() {
                            _selectedVehicle = VehicleType.motor;
                            _selectedEngineClass = null;
                            _selectedMotorRon = null;
                            _selectedCarClass = null;
                            _selectedCarRon = null;
                            _selectedBusSize = null;
                            _selectedBusFuel = null;
                            _selectedEvBattery = null;
                            _selectedEvPower = null;
                          });
                          _updateEmission();
                        },
                      ),
                      _VehicleTypeChip(
                        label: 'Mobil listrik',
                        icon: Icons.electric_car,
                        isSelected:
                            _selectedVehicle == VehicleType.mobilListrik,
                        onTap: () {
                          setState(() {
                            _selectedVehicle = VehicleType.mobilListrik;
                            _selectedEvBattery = null;
                            _selectedEvPower = null;
                            _selectedEngineClass = null;
                            _selectedMotorRon = null;
                            _selectedCarClass = null;
                            _selectedCarRon = null;
                            _selectedBusSize = null;
                            _selectedBusFuel = null;
                          });
                          _updateEmission();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ==== OPSI DETAIL SESUAI KENDARAAN ====
                  if (_selectedVehicle == VehicleType.motor) ...[
                    Text(
                      'Kapasitas mesin motor',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _OptionChip(
                          label: '<= 125 cc',
                          isSelected:
                              _selectedEngineClass == EngineClass.small,
                          onTap: () {
                            setState(
                                () => _selectedEngineClass = EngineClass.small);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: '126-250 cc',
                          isSelected:
                              _selectedEngineClass == EngineClass.medium,
                          onTap: () {
                            setState(() =>
                                _selectedEngineClass = EngineClass.medium);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: '> 250 cc',
                          isSelected:
                              _selectedEngineClass == EngineClass.large,
                          onTap: () {
                            setState(
                                () => _selectedEngineClass = EngineClass.large);
                            _updateEmission();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Angka oktan (RON)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
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
                              _updateEmission();
                            },
                          ),
                      ],
                    ),
                  ] else if (_selectedVehicle == VehicleType.mobil) ...[
                    Text(
                      'Kelas mobil (cc)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _OptionChip(
                          label: 'Kecil (<=1300 cc)',
                          isSelected: _selectedCarClass == CarClass.small,
                          onTap: () {
                            setState(() => _selectedCarClass = CarClass.small);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: 'Sedang (1301-1800)',
                          isSelected: _selectedCarClass == CarClass.medium,
                          onTap: () {
                            setState(
                                () => _selectedCarClass = CarClass.medium);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: 'Besar (>1800 cc)',
                          isSelected: _selectedCarClass == CarClass.large,
                          onTap: () {
                            setState(() => _selectedCarClass = CarClass.large);
                            _updateEmission();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Angka oktan (RON)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
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
                              _updateEmission();
                            },
                          ),
                      ],
                    ),
                  ] else if (_selectedVehicle == VehicleType.bus) ...[
                    Text(
                      'Ukuran bus',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _OptionChip(
                          label: 'Kecil (<20 kursi)',
                          isSelected: _selectedBusSize == BusSize.small,
                          onTap: () {
                            setState(() => _selectedBusSize = BusSize.small);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: 'Sedang (25-35)',
                          isSelected: _selectedBusSize == BusSize.medium,
                          onTap: () {
                            setState(() => _selectedBusSize = BusSize.medium);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: 'Besar (40-60)',
                          isSelected: _selectedBusSize == BusSize.large,
                          onTap: () {
                            setState(() => _selectedBusSize = BusSize.large);
                            _updateEmission();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Jenis bahan bakar',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _OptionChip(
                          label: 'Diesel',
                          isSelected: _selectedBusFuel == BusFuel.diesel,
                          onTap: () {
                            setState(() => _selectedBusFuel = BusFuel.diesel);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: 'Gas alam',
                          isSelected: _selectedBusFuel == BusFuel.gas,
                          onTap: () {
                            setState(() => _selectedBusFuel = BusFuel.gas);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: 'Listrik',
                          isSelected: _selectedBusFuel == BusFuel.electric,
                          onTap: () {
                            setState(
                                () => _selectedBusFuel = BusFuel.electric);
                            _updateEmission();
                          },
                        ),
                      ],
                    ),
                  ] else if (_selectedVehicle == VehicleType.mobilListrik) ...[
                    Text(
                      'Kapasitas baterai',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _OptionChip(
                          label: 'Kecil (<40 kWh)',
                          isSelected:
                              _selectedEvBattery == EvBatteryClass.small,
                          onTap: () {
                            setState(() =>
                                _selectedEvBattery = EvBatteryClass.small);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: 'Sedang (40-70)',
                          isSelected:
                              _selectedEvBattery == EvBatteryClass.medium,
                          onTap: () {
                            setState(() =>
                                _selectedEvBattery = EvBatteryClass.medium);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: 'Besar (>70 kWh)',
                          isSelected:
                              _selectedEvBattery == EvBatteryClass.large,
                          onTap: () {
                            setState(() =>
                                _selectedEvBattery = EvBatteryClass.large);
                            _updateEmission();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sumber daya',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _OptionChip(
                          label: 'Listrik PLN',
                          isSelected: _selectedEvPower == EvPowerSource.pln,
                          onTap: () {
                            setState(
                                () => _selectedEvPower = EvPowerSource.pln);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: 'Solar panel',
                          isSelected:
                              _selectedEvPower == EvPowerSource.solarPanel,
                          onTap: () {
                            setState(() =>
                                _selectedEvPower = EvPowerSource.solarPanel);
                            _updateEmission();
                          },
                        ),
                        _OptionChip(
                          label: 'Fast charging',
                          isSelected: _selectedEvPower ==
                              EvPowerSource.fastCharging,
                          onTap: () {
                            setState(() =>
                                _selectedEvPower = EvPowerSource.fastCharging);
                            _updateEmission();
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================== HASIL EMISI ====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildEmissionResultSection(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LOGIKA MAP & RUTE ====================

  void _onMapTap(LatLng latlng) {
    setState(() {
      if (_startPoint == null) {
        _startPoint = latlng;
        _endPoint = null;
        _routePoints = [];
        _distanceKm = null;
        _emissionGrams = null;
      } else if (_endPoint == null) {
        _endPoint = latlng;
      } else {
        // mulai rute baru
        _startPoint = latlng;
        _endPoint = null;
        _routePoints = [];
        _distanceKm = null;
        _emissionGrams = null;
      }
    });

    if (_startPoint != null && _endPoint != null) {
      _fetchRoute();
    }
  }

  Future<void> _fetchRoute() async {
    if (_startPoint == null || _endPoint == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final start = _startPoint!;
      final end = _endPoint!;

      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List<dynamic>;
        if (routes.isNotEmpty) {
          final route = routes[0];
          final distanceMeters = (route['distance'] as num).toDouble();
          final geometry = route['geometry'];
          final coords = (geometry['coordinates'] as List<dynamic>)
              .map<LatLng>((c) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();

          setState(() {
            _distanceKm = distanceMeters / 1000.0;
            _routePoints = coords;
          });
          _updateEmission();
        }
      } else {
        _computeStraightLineFallback();
      }
    } catch (e) {
      _computeStraightLineFallback();
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _computeStraightLineFallback() {
    if (_startPoint == null || _endPoint == null) return;
    final Distance distanceCalc = const Distance();
    final double meters = distanceCalc(_startPoint!, _endPoint!);
    setState(() {
      _distanceKm = meters / 1000.0;
      _routePoints = [_startPoint!, _endPoint!];
    });
    _updateEmission();
  }

  void _resetAll() {
    setState(() {
      _startPoint = null;
      _endPoint = null;
      _distanceKm = null;
      _routePoints = [];
      _selectedVehicle = null;
      _selectedEngineClass = null;
      _selectedMotorRon = null;
      _selectedCarClass = null;
      _selectedCarRon = null;
      _selectedBusSize = null;
      _selectedBusFuel = null;
      _selectedEvBattery = null;
      _selectedEvPower = null;
      _emissionGrams = null;
    });
  }

  // ==================== PERHITUNGAN EMISI ====================

  void _updateEmission() {
    if (_distanceKm == null || _selectedVehicle == null) {
      setState(() => _emissionGrams = null);
      return;
    }

    final double? factor = _currentEmissionFactorPerKm();
    if (factor == null) {
      setState(() => _emissionGrams = null);
      return;
    }

    setState(() {
      _emissionGrams = factor * _distanceKm!;
    });
  }

  double? _currentEmissionFactorPerKm() {
    switch (_selectedVehicle) {
      case VehicleType.motor:
        if (_selectedEngineClass == null || _selectedMotorRon == null) {
          return null;
        }
        return kMotorEmissionFactors[_selectedEngineClass]?[_selectedMotorRon];

      case VehicleType.mobil:
        if (_selectedCarClass == null || _selectedCarRon == null) {
          return null;
        }
        return kCarEmissionFactors[_selectedCarClass]?[_selectedCarRon];

      case VehicleType.bus:
        if (_selectedBusSize == null || _selectedBusFuel == null) {
          return null;
        }
        return kBusEmissionFactors[_selectedBusSize]?[_selectedBusFuel];

      case VehicleType.mobilListrik:
        if (_selectedEvBattery == null || _selectedEvPower == null) {
          return null;
        }
        return kEvEmissionFactors[_selectedEvBattery]?[_selectedEvPower];

      case null:
        return null;
    }
  }

  Widget _buildEmissionResultSection() {
    if (_distanceKm == null) {
      return const _EmptyHint(
        message:
            'Tap lokasi asal dan tujuan di peta untuk menghitung jarak & emisi.',
      );
    }

    if (_selectedVehicle == null) {
      return const _EmptyHint(
        message:
            'Pilih jenis kendaraan dan detailnya untuk melihat estimasi emisi karbon.',
      );
    }

    if (_currentEmissionFactorPerKm() == null || _emissionGrams == null) {
      return const _EmptyHint(
        message:
            'Lengkapi dulu pilihan kapasitas mesin / kelas kendaraan dan jenis bahan bakar.',
      );
    }

    final double km = _distanceKm!;
    final double grams = _emissionGrams!;
    final double kg = grams / 1000.0;
    final double factor = _currentEmissionFactorPerKm()!;

    final theme = Theme.of(context);

    // Desain kartu mirip Hitung Emisi (ada logo & subtitle)
    return Row(
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
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.eco, color: Colors.white);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perkiraan Emisi Karbon',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Simulasi I-TransEC untuk perjalananmu',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jarak: ${km.toStringAsFixed(2)} km',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Faktor emisi: ${factor.toStringAsFixed(0)} g CO₂/km',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.black.withOpacity(0.08)),
              const SizedBox(height: 8),
              Text(
                'Total emisi perjalanan ini',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${kg.toStringAsFixed(2)} kg CO₂',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nilai ini merupakan estimasi berdasarkan jarak rute, jenis kendaraan, kapasitas mesin/baterai, dan jenis bahan bakar yang kamu pilih.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== WIDGET KECIL2 ====================

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _VehicleTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleTypeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              offset: const Offset(0, 2),
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF4CAF50)
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? const Color(0xFF2E7D32) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint({this.message = ''});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        message.isEmpty
            ? 'Tap lokasi asal dan tujuan di peta untuk menghitung jarak & emisi 🚗🌱'
            : message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}
