import 'package:flutter/material.dart';

class DetailEmisiPage extends StatefulWidget {
  final String vehicleType;

  const DetailEmisiPage({
    super.key,
    this.vehicleType = "Mobil",
  });

  @override
  State<DetailEmisiPage> createState() => _DetailEmisiPageState();
}

class _DetailEmisiPageState extends State<DetailEmisiPage> {
  String? _kapasitasMesin;
  String? _bahanBakar;
  final TextEditingController _jarakController = TextEditingController();
  double? _hasilEmisi;

  // Faktor emisi dasar per jenis kendaraan (kg CO2 per km)
  final Map<String, double> _baseEmissionFactors = {
    "Mobil": 0.21,
    "Bus": 0.089,
    "Motor": 0.084,
    "Mobil listrik": 0.05,
  };

  // ✅ Opsi kapasitas untuk setiap kendaraan
  Map<String, List<String>> _kapasitasOptions = {
    "Mobil": ["1000-1999 CC", "2000-2999 CC", "3000-3900 CC"],
    "Bus": ["Kecil (< 20 kursi)", "Sedang (20-40 kursi)", "Besar (> 40 kursi)"],
    "Motor": ["< 150 CC", "150-250 CC", "> 250 CC"],
    "Mobil listrik": ["Kecil (< 40 kWh)", "Sedang (40-70 kWh)", "Besar (> 70 kWh)"],
  };

  // ✅ Opsi bahan bakar untuk setiap kendaraan
  Map<String, List<String>> _bahanBakarOptions = {
    "Mobil": ["Solar", "Pertamax", "Pertalite"],
    "Bus": ["Solar", "Gas", "Biodiesel"],
    "Motor": ["Bensin", "Elektrik"],
    "Mobil listrik": ["Listrik PLN", "Solar Panel", "Fast Charging"],
  };

  // ✅ Multiplier berdasarkan kapasitas (disesuaikan per kendaraan)
  Map<String, Map<String, double>> _engineMultiplier = {
    "Mobil": {
      "1000-1999 CC": 1.0,
      "2000-2999 CC": 1.3,
      "3000-3900 CC": 1.6,
    },
    "Bus": {
      "Kecil (< 20 kursi)": 0.8,
      "Sedang (20-40 kursi)": 1.0,
      "Besar (> 40 kursi)": 1.3,
    },
    "Motor": {
      "< 150 CC": 0.8,
      "150-250 CC": 1.0,
      "> 250 CC": 1.2,
    },
    "Mobil listrik": {
      "Kecil (< 40 kWh)": 0.8,
      "Sedang (40-70 kWh)": 1.0,
      "Besar (> 70 kWh)": 1.2,
    },
  };

  // ✅ Multiplier berdasarkan bahan bakar
  Map<String, Map<String, double>> _fuelMultiplier = {
    "Mobil": {
      "Solar": 1.1,
      "Pertamax": 1.0,
      "Pertalite": 0.95,
    },
    "Bus": {
      "Solar": 1.0,
      "Gas": 0.85,
      "Biodiesel": 0.9,
    },
    "Motor": {
      "Bensin": 1.0,
      "Elektrik": 0.6,
    },
    "Mobil listrik": {
      "Listrik PLN": 1.0,
      "Solar Panel": 0.5,
      "Fast Charging": 1.1,
    },
  };

  String _getVehicleIcon() {
    switch (widget.vehicleType) {
      case "Bus":
        return "assets/splash/icons/bus.png";
      case "Motor":
        return "assets/splash/icons/motor.png";
      case "Mobil listrik":
        return "assets/splash/icons/mobil_listrik.png";
      default:
        return "assets/splash/icons/mobil.png";
    }
  }

  IconData _getFallbackIcon() {
    switch (widget.vehicleType) {
      case "Bus":
        return Icons.directions_bus;
      case "Motor":
        return Icons.two_wheeler;
      case "Mobil listrik":
        return Icons.electric_car;
      default:
        return Icons.directions_car;
    }
  }

  void _hitungEmisi() {
    final jarak = double.tryParse(_jarakController.text);

    if (jarak == null || jarak <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Masukkan jarak yang valid"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Semua kendaraan sekarang memerlukan input lengkap
    if (_kapasitasMesin == null || _bahanBakar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.vehicleType == "Mobil listrik"
                ? "Pilih kapasitas baterai dan sumber daya terlebih dahulu"
                : "Pilih kapasitas dan bahan bakar terlebih dahulu",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final baseFactor = _baseEmissionFactors[widget.vehicleType] ?? 0.21;
    final engineMult = _engineMultiplier[widget.vehicleType]?[_kapasitasMesin] ?? 1.0;
    final fuelMult = _fuelMultiplier[widget.vehicleType]?[_bahanBakar] ?? 1.0;

    setState(() {
      _hasilEmisi = jarak * baseFactor * engineMult * fuelMult;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Ambil opsi berdasarkan jenis kendaraan
    final kapasitasOpts = _kapasitasOptions[widget.vehicleType] ?? [];
    final bahanBakarOpts = _bahanBakarOptions[widget.vehicleType] ?? [];

    // ✅ Label dinamis
    String kapasitasLabel = "Kapasitas mesin";
    String bahanBakarLabel = "Jenis bahan bakar";

    if (widget.vehicleType == "Bus") {
      kapasitasLabel = "Ukuran bus";
      bahanBakarLabel = "Jenis bahan bakar";
    } else if (widget.vehicleType == "Motor") {
      kapasitasLabel = "Kapasitas mesin";
      bahanBakarLabel = "Jenis bahan bakar";
    } else if (widget.vehicleType == "Mobil listrik") {
      kapasitasLabel = "Kapasitas baterai";
      bahanBakarLabel = "Sumber daya";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: Text("Hitung Emisi ${widget.vehicleType}"),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Kalkulator Emisi Kendaraan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Menghitung emisi karbon kendaraan",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 25),

              // ✅ Gambar kendaraan
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        _getVehicleIcon(),
                        width: 100,
                        height: 100,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _getFallbackIcon(),
                            size: 100,
                            color: const Color(0xFF4CAF50),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.vehicleType,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ✅ Kapasitas (untuk semua kendaraan)
              Text(
                kapasitasLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kapasitasOpts
                    .map((opt) => _buildChip(opt))
                    .toList(),
              ),
              const SizedBox(height: 30),

              // ✅ Bahan bakar (untuk semua kendaraan)
              Text(
                bahanBakarLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: bahanBakarOpts
                    .map((opt) => _buildFuelCard(opt, Icons.local_gas_station))
                    .toList(),
              ),
              const SizedBox(height: 30),

              // ✅ Input jarak
              const Text(
                "Jarak perjalanan",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _jarakController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Contoh: 10",
                  suffixText: "km",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ✅ Tombol hitung
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _hitungEmisi,
                  child: const Text(
                    "Hitung Emisi",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ✅ Hasil perhitungan
              if (_hasilEmisi != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.eco,
                        color: Color(0xFF4CAF50),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Total Emisi CO₂",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${_hasilEmisi!.toStringAsFixed(2)} kg",
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${widget.vehicleType} • ${_jarakController.text} km",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      if (_kapasitasMesin != null && _bahanBakar != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "$_kapasitasMesin • $_bahanBakar",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _kapasitasMesin == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _kapasitasMesin = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFuelCard(String label, IconData icon) {
    final isSelected = _bahanBakar == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _bahanBakar = label;
        });
      },
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _jarakController.dispose();
    super.dispose();
  }
}