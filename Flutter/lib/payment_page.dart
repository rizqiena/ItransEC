// lib/payment_page.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import 'webview_page.dart';

class PaymentPage extends StatefulWidget {
  final double? emisiKg;
  final double totalEmisi;
  final double hargaPerKg;
  final String vehicleType;
  final double distanceKm;
  final String fuelType;
  final String kapasitas;
  final String bahanBakar;
  final double jarak;
  final bool isTebusEmisi; // FLAG untuk mode Tebus Emisi

  const PaymentPage({
    super.key,
    this.emisiKg,
    this.totalEmisi = 0.0,
    this.hargaPerKg = 1000.0,
    this.vehicleType = '',
    this.distanceKm = 0.0,
    this.fuelType = '',
    this.kapasitas = '',
    this.bahanBakar = '',
    this.jarak = 0.0,
    this.isTebusEmisi = false,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with WidgetsBindingObserver {
  String metode = "Pilih metode pembayaran";
  bool isPaying = false;

  // Keys untuk SharedPreferences
  static const _kSavedTotalEmisi = 'total_emisi';
  static const _kLastSessionEmisi = 'last_session_emisi';
  static const _kSavedHargaKg = 'saved_harga_kg';
  static const _kSavedJarak = 'saved_jarak';
  static const _kSavedVehicle = 'saved_vehicle';
  static const _kSavedKapasitas = 'saved_kapasitas';
  static const _kSavedBahanBakar = 'saved_bahan_bakar';
  static const _kSavedFuelType = 'saved_fueltype';
  static const _kUserData = 'user_data';
  static const _kName = 'name';
  static const _kEmail = 'email';
  static const _kPhone = 'phone';
  static const _kHistoryTebusEmisi = 'history_tebus_emisi';

  double _savedTotalEmisi = 0.0;
  double _sessionEmisi = 0.0;
  double _hargaPerKg = 1000.0;

  String _vehicleType = '';
  String _kapasitas = '';
  String _bahanBakar = '';
  double _jarak = 0.0;
  String _fuelType = '';

  // State untuk Tebus Emisi
  double _totalEmisiTersedia = 0.0;
  double _emisiDitebus = 0.0;
  List<Map<String, dynamic>> _historyTebusEmisi = [];
  bool _loadingHistory = false;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.isTebusEmisi) {
      // Mode Tebus Emisi - LANGSUNG LOAD DATA
      print("🔵 [PaymentPage] initState - Mode Tebus Emisi");
      _loadTotalEmisi();
      _loadHistoryTebusEmisi();
    } else {
      // Mode Hitung Emisi (dari tracking GPS)
      _sessionEmisi = widget.emisiKg ?? 0.0;
      _vehicleType = widget.vehicleType;
      _kapasitas = widget.kapasitas;
      _bahanBakar = widget.bahanBakar;
      _jarak = widget.jarak != 0.0 ? widget.jarak : widget.distanceKm;
      _fuelType = widget.fuelType;
    }

    if (widget.hargaPerKg > 0) _hargaPerKg = widget.hargaPerKg;

    _loadLocalState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualInputController.dispose();
    super.dispose();
  }

  // ===== FIX UTAMA: RELOAD SETIAP KALI APP RESUME =====
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && widget.isTebusEmisi) {
      print("🔄 [PaymentPage] App resumed - Reload data emisi");
      _loadTotalEmisi();
    }
  }

  // ===== FIX: RELOAD DATA SETIAP KALI HALAMAN MUNCUL KEMBALI =====
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Reload total emisi setiap kali halaman muncul
    if (widget.isTebusEmisi) {
      print("🔄 [PaymentPage] didChangeDependencies - Reload data");
      _loadTotalEmisi();
      _loadHistoryTebusEmisi();
    }
  }

  // ===== FIX: FORCE RELOAD SAAT BUILD PERTAMA KALI =====
  bool _isFirstBuild = true;

  @override
  Widget build(BuildContext context) {
    // Force reload pada build pertama untuk Tebus Emisi
    if (_isFirstBuild && widget.isTebusEmisi) {
      _isFirstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("🔄 [PaymentPage] First build - Force reload");
        _loadTotalEmisi();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.isTebusEmisi ? "Tebus Emisi" : "Pembayaran Emisi",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!widget.isTebusEmisi)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.red.shade600),
              onPressed: _resetAll,
              tooltip: "Reset Total Emisi",
            ),
          // ✅ TAMBAH: Button refresh manual untuk Tebus Emisi
          if (widget.isTebusEmisi)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.green.shade600),
              onPressed: () {
                print("🔄 [PaymentPage] Manual refresh clicked");
                _loadTotalEmisi();
                _loadHistoryTebusEmisi();
              },
              tooltip: "Refresh Data Emisi",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // MODE: TEBUS EMISI
            if (widget.isTebusEmisi) ...[
              _buildTebusEmisiSection(),
              const SizedBox(height: 16),
              _buildPresetButtons(),
              const SizedBox(height: 16),
              _buildSliderSection(),
              const SizedBox(height: 16),
              _buildManualInputSection(),
              const SizedBox(height: 16),
              _buildMotivasiCard(),
              const Divider(height: 32, thickness: 2),
              _buildRingkasanTebusEmisi(),
            ]
            // MODE: HITUNG EMISI (dari tracking GPS)
            else ...[
              _buildEmisiHeader(),
              const SizedBox(height: 20),
              _buildRingkasanPembayaran(),
              const SizedBox(height: 20),
              _buildDetailKendaraan(),
              const SizedBox(height: 22),
              _buildSaveEmisiButton(),
              const SizedBox(height: 12),
            ],

            // BUTTON BAYAR (untuk semua mode)
            _buildPaymentButton(),

            // HISTORY (hanya untuk mode Tebus Emisi)
            if (widget.isTebusEmisi) ...[
              const SizedBox(height: 30),
              _buildHistorySection(),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ===== REVISI FUNGSI _loadTotalEmisi =====
  Future<void> _loadTotalEmisi() async {
    try {
      print("📥 [PaymentPage] Loading total emisi from SharedPreferences...");

      final prefs = await SharedPreferences.getInstance();

      // ✅ FIX: Paksa reload dari SharedPreferences
      await prefs.reload();

      final total = prefs.getDouble(_kSavedTotalEmisi) ?? 0.0;

      print("🔄 [PaymentPage] RELOAD TOTAL EMISI: ${total.toStringAsFixed(3)} kg");

      if (mounted) {
        setState(() {
          _totalEmisiTersedia = total;

          // Set default value
          if (total > 0) {
            _emisiDitebus = total * 0.5;
          } else {
            _emisiDitebus = 0.0;
          }

          _manualInputController.text = _emisiDitebus.toStringAsFixed(2);
        });

        print("✅ [PaymentPage] State updated - Total: ${_totalEmisiTersedia.toStringAsFixed(3)} kg");
      }
    } catch (e) {
      debugPrint('❌ [PaymentPage] Error loading total emisi: $e');
    }
  }

  Future<void> _loadHistoryTebusEmisi() async {
    setState(() => _loadingHistory = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Force reload

      List<String> historyList = prefs.getStringList(_kHistoryTebusEmisi) ?? [];

      setState(() {
        _historyTebusEmisi = historyList
            .map((e) => jsonDecode(e) as Map<String, dynamic>)
            .toList();
        _loadingHistory = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading history: $e');
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _saveHistoryTebusEmisi(double emisiKg, double nominal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> historyList = prefs.getStringList(_kHistoryTebusEmisi) ?? [];

      final newHistory = {
        'date': DateTime.now().toIso8601String(),
        'emisi_kg': emisiKg,
        'nominal': nominal,
      };

      historyList.insert(0, jsonEncode(newHistory));

      // Limit history maksimal 50 item
      if (historyList.length > 50) {
        historyList = historyList.sublist(0, 50);
      }

      await prefs.setStringList(_kHistoryTebusEmisi, historyList);

      // Reload history
      await _loadHistoryTebusEmisi();
    } catch (e) {
      debugPrint('❌ Error saving history: $e');
    }
  }

  Future<void> _loadLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final saved = prefs.getDouble(_kSavedTotalEmisi);
      _savedTotalEmisi = saved ?? 0.0;

      final harga = prefs.getDouble(_kSavedHargaKg);
      if (harga != null) _hargaPerKg = harga;

      final jarak = prefs.getDouble(_kSavedJarak);
      if (jarak != null && _jarak == 0.0) _jarak = jarak;

      final veh = prefs.getString(_kSavedVehicle);
      if (veh != null && _vehicleType.isEmpty) _vehicleType = veh;

      final cap = prefs.getString(_kSavedKapasitas);
      if (cap != null && _kapasitas.isEmpty) _kapasitas = cap;

      final bb = prefs.getString(_kSavedBahanBakar);
      if (bb != null && _bahanBakar.isEmpty) _bahanBakar = bb;

      final fuel = prefs.getString(_kSavedFuelType);
      if (fuel != null && _fuelType.isEmpty) _fuelType = fuel;

      if (!widget.isTebusEmisi && (widget.emisiKg == null || widget.emisiKg == 0.0)) {
        final last = prefs.getDouble(_kLastSessionEmisi) ?? 0.0;
        if (last > 0) _sessionEmisi = last;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading local state: $e');
    }
  }

  Future<void> _saveSessionEmisi() async {
    if (_sessionEmisi <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada emisi perjalanan untuk disimpan.")),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final oldTotal = prefs.getDouble(_kSavedTotalEmisi) ?? 0.0;
      final newTotal = oldTotal + _sessionEmisi;

      await prefs.setDouble(_kSavedTotalEmisi, newTotal);
      await prefs.setDouble(_kLastSessionEmisi, 0.0);

      await prefs.setDouble(_kSavedHargaKg, _hargaPerKg);
      await prefs.setDouble(_kSavedJarak, _jarak);

      if (_vehicleType.isNotEmpty) await prefs.setString(_kSavedVehicle, _vehicleType);
      if (_kapasitas.isNotEmpty) await prefs.setString(_kSavedKapasitas, _kapasitas);
      if (_bahanBakar.isNotEmpty) await prefs.setString(_kSavedBahanBakar, _bahanBakar);
      if (_fuelType.isNotEmpty) await prefs.setString(_kSavedFuelType, _fuelType);

      setState(() {
        _savedTotalEmisi = newTotal;
        _sessionEmisi = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Emisi tersimpan. Total: ${newTotal.toStringAsFixed(3)} Kg"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan emisi: $e")),
      );
    }
  }

  Future<void> _resetAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_kSavedTotalEmisi, 0.0);
    await prefs.setDouble(_kLastSessionEmisi, 0.0);

    await prefs.remove(_kSavedVehicle);
    await prefs.remove(_kSavedKapasitas);
    await prefs.remove(_kSavedBahanBakar);
    await prefs.remove(_kSavedFuelType);
    await prefs.remove(_kSavedJarak);

    setState(() {
      _savedTotalEmisi = 0.0;
      _sessionEmisi = 0.0;
      _totalEmisiTersedia = 0.0;
      _emisiDitebus = 0.0;
      _vehicleType = '';
      _kapasitas = '';
      _bahanBakar = '';
      _fuelType = '';
      _jarak = 0.0;
      _manualInputController.text = '0.00';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Total emisi berhasil di-reset."),
          backgroundColor: Colors.orange),
    );
  }

  Future<void> _createPayment() async {
    setState(() => isPaying = true);

    double emisiToPay = 0.0;

    if (widget.isTebusEmisi) {
      // Mode Tebus Emisi - HAPUS SEMUA VALIDASI, langsung ambil nilai
      emisiToPay = _emisiDitebus;

      // Jika emisi = 0, tampilkan pesan tapi tetap lanjut
      if (emisiToPay <= 0) {
        setState(() => isPaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Jumlah emisi yang ditebus adalah 0 kg")),
        );
        return;
      }
    } else {
      // Mode Hitung Emisi
      emisiToPay = _sessionEmisi > 0 ? _sessionEmisi : _savedTotalEmisi;
    }

    if (emisiToPay <= 0) {
      setState(() => isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada emisi untuk dibayarkan.")),
      );
      return;
    }

    final amount = ApiService.computeAmount(emisiToPay, _hargaPerKg);
    final user = await _getUserData();

    try {
      final result = await ApiService.createPayment(
        amount: amount.toDouble(),
        emisi: emisiToPay,
        name: user['name']!,
        email: user['email']!,
        phone: user['phone']!,
      );

      setState(() => isPaying = false);

      if (result != null && result['success'] == true) {
        final url = result['redirect_url'] ?? '';

        // Update emisi setelah payment sukses (sebelum redirect)
        if (widget.isTebusEmisi) {
          await _updateTebusEmisi();
        }

        if (!kIsWeb) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WebViewPage(paymentUrl: url)),
          );
        } else {
          final uri = Uri.tryParse(url);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result?['message'] ?? "Gagal membuat pembayaran.")),
        );
      }
    } catch (e) {
      setState(() => isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saat membuat pembayaran: $e")),
      );
    }
  }

  Future<void> _updateTebusEmisi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sisaEmisi = (_totalEmisiTersedia - _emisiDitebus).clamp(0.0, double.infinity);

      await prefs.setDouble(_kSavedTotalEmisi, sisaEmisi);

      print("✅ UPDATE TEBUS EMISI: Sisa = ${sisaEmisi.toStringAsFixed(3)} kg");

      // Simpan history
      await _saveHistoryTebusEmisi(_emisiDitebus, _emisiDitebus * _hargaPerKg);

      setState(() {
        _totalEmisiTersedia = sisaEmisi;

        // Update nilai ditebus
        if (sisaEmisi > 0) {
          _emisiDitebus = sisaEmisi * 0.5;
        } else {
          _emisiDitebus = 0.0;
        }

        _manualInputController.text = _emisiDitebus.toStringAsFixed(2);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Berhasil menebus ${_emisiDitebus.toStringAsFixed(2)} kg emisi! 🌱'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error updating tebus emisi: $e');
    }
  }

  Future<Map<String, String>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserData);

    if (raw != null && raw.isNotEmpty) {
      try {
        final json = jsonDecode(raw);
        return {
          'name': json['Nama_Masyarakat'] ?? 'User',
          'email': json['Email_Masyarakat'] ?? 'user@example.com',
          'phone': json['No_Hp_Masyarakat'] ?? '081234567890',
        };
      } catch (_) {}
    }

    return {
      'name': prefs.getString(_kName) ?? 'User',
      'email': prefs.getString(_kEmail) ?? 'user@example.com',
      'phone': prefs.getString(_kPhone) ?? '081234567890',
    };
  }

  void _setPreset(double percentage) {
    if (_totalEmisiTersedia <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Belum ada emisi yang tersimpan")),
      );
      return;
    }

    setState(() {
      _emisiDitebus = _totalEmisiTersedia * percentage;
      _manualInputController.text = _emisiDitebus.toStringAsFixed(2);
    });
  }

  // ==================== WIDGETS UNTUK MODE TEBUS EMISI ====================

  Widget _buildTebusEmisiSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Total Emisi Kamu Saat Ini',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF2E7D32),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌍', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                _totalEmisiTersedia.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kg CO₂',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButtons() {
    return Row(
      children: [
        Expanded(child: _presetButton('25%', 0.25)),
        const SizedBox(width: 8),
        Expanded(child: _presetButton('50%', 0.5)),
        const SizedBox(width: 8),
        Expanded(child: _presetButton('75%', 0.75)),
        const SizedBox(width: 8),
        Expanded(child: _presetButton('Semua', 1.0)),
      ],
    );
  }

  Widget _presetButton(String label, double percentage) {
    return ElevatedButton(
      onPressed: () => _setPreset(percentage),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4CAF50),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSliderSection() {
    // Validasi nilai slider untuk menghindari error
    final minValue = 0.0;
    final maxValue = _totalEmisiTersedia > 0 ? _totalEmisiTersedia : 1.0;
    final currentValue = _emisiDitebus.clamp(minValue, maxValue);

    // Pastikan divisions tidak 0 atau negatif
    final divisions = (maxValue * 10).toInt().clamp(1, 1000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            'Berapa emisi yang ingin kamu tebus?',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${currentValue.toStringAsFixed(2)} kg',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
          Slider(
            value: currentValue,
            min: minValue,
            max: maxValue,
            divisions: divisions,
            activeColor: const Color(0xFF4CAF50),
            onChanged: (value) {
              setState(() {
                _emisiDitebus = value;
                _manualInputController.text = value.toStringAsFixed(2);
              });
            },
          ),
          if (_totalEmisiTersedia <= 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Belum ada emisi yang tersimpan',
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atau ketik manual:',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualInputController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    final val = double.tryParse(value) ?? 0.0;
                    setState(() {
                      _emisiDitebus = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotivasiCard() {
    final emisiValid = _emisiDitebus > 0 ? _emisiDitebus : 0.1;
    final pohon = (emisiValid / 2.5).floor();
    String motivasiText = '';

    if (emisiValid >= 10) {
      motivasiText = '${emisiValid.toStringAsFixed(2)} kg CO₂ setara dengan menanam $pohon pohon dan menyerap karbon selama 1 tahun! 🎉';
    } else if (emisiValid >= 5) {
      motivasiText = '${emisiValid.toStringAsFixed(2)} kg CO₂ setara dengan menanam $pohon pohon. Teruskan langkah baikmu! 🌳';
    } else {
      motivasiText = '${emisiValid.toStringAsFixed(2)} kg CO₂ akan membantu menyerap karbon setara $pohon pohon kecil. Setiap langkah kecil berarti! 💚';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFF59D)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              motivasiText,
              style: GoogleFonts.poppins(
                color: const Color(0xFF827717),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasanTebusEmisi() {
    final totalDonasi = _emisiDitebus * _hargaPerKg;
    final sisaEmisi = (_totalEmisiTersedia - _emisiDitebus).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Emisi yang ditebus:', '${_emisiDitebus.toStringAsFixed(2)} kg'),
          const SizedBox(height: 8),
          _summaryRow(
            'Total donasi:',
            'Rp ${NumberFormat('#,###', 'id_ID').format(totalDonasi)}',
            highlight: true,
          ),
          const SizedBox(height: 8),
          _summaryRow('Sisa emisi:', '${sisaEmisi.toStringAsFixed(2)} kg'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: highlight ? 18 : 14,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? const Color(0xFF4CAF50) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Tebus Emisi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            )
          else if (_historyTebusEmisi.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada riwayat tebus emisi',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historyTebusEmisi.length,
              itemBuilder: (context, index) {
                final item = _historyTebusEmisi[index];
                final date = DateTime.parse(item['date']);
                final emisi = item['emisi_kg'];
                final nominal = item['nominal'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: const Color(0xFFF5F5F5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 20),
                    ),
                    title: Text(
                      '${emisi.toStringAsFixed(2)} kg CO₂',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date),
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(nominal)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==================== WIDGETS UNTUK MODE HITUNG EMISI ====================

  Widget _buildEmisiHeader() {
    final emisiDisplay = _sessionEmisi > 0 ? _sessionEmisi : _savedTotalEmisi;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sessionEmisi > 0
                ? "Emisi Perjalanan (Belum Disimpan)"
                : "Total Emisi Tersimpan",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            "${emisiDisplay.toStringAsFixed(3)} Kg CO₂",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasanPembayaran() {
    final emisiDisplay = _sessionEmisi > 0 ? _sessionEmisi : _savedTotalEmisi;
    final totalPembayaran = (emisiDisplay * _hargaPerKg).round().toDouble();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          _row("Emisi yg dibayar", "${emisiDisplay.toStringAsFixed(3)} Kg"),
          const Divider(height: 22),
          _row("Konversi Emisi", "Rp ${totalPembayaran.toStringAsFixed(0)}"),
          const Divider(height: 22),
          _row("Total Pembayaran", "Rp ${totalPembayaran.toStringAsFixed(0)}", bold: true),
        ],
      ),
    );
  }

  Widget _buildDetailKendaraan() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Detail Kendaraan",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _row("Jenis Kendaraan", _vehicleType.isEmpty ? "-" : _vehicleType),
          _row("Kapasitas", _kapasitas.isEmpty ? "-" : _kapasitas),
          _row("Bahan Bakar", _bahanBakar.isEmpty ? "-" : _bahanBakar),
          _row("Jarak (km)", "${_jarak.toStringAsFixed(2)} km"),
        ],
      ),
    );
  }

  Widget _buildSaveEmisiButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveSessionEmisi,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          "SIMPAN EMISI",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isPaying ? null : _createPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
        ),
        child: isPaying
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          widget.isTebusEmisi ? "TEBUS SEKARANG" : "BAYAR SEKARANG",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _row(String left, String right, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: GoogleFonts.poppins(fontSize: 14)),
          Text(
            right,
            style: GoogleFonts.poppins(
              fontSize: bold ? 17 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}