// lib/payment_page.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'webview_page.dart';

class PaymentPage extends StatefulWidget {
  final double emisiKg;
  final double totalEmisi;
  final double hargaPerKg;
  final String vehicleType;
  final double distanceKm;
  final String fuelType;

  final String kapasitas;
  final String bahanBakar;
  final double jarak;

  const PaymentPage({
    super.key,
    this.emisiKg = 0.0,
    this.totalEmisi = 0.0,
    this.hargaPerKg = 1000.0,
    this.vehicleType = '',
    this.distanceKm = 0.0,
    this.fuelType = '',
    this.kapasitas = '',
    this.bahanBakar = '',
    this.jarak = 0.0,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String metode = "Pilih metode pembayaran";
  bool isPaying = false;

  // FIX → gunakan key yang SAMA dengan HitungEmisiPage
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

  double _savedTotalEmisi = 0.0;
  double _sessionEmisi = 0.0;
  double _hargaPerKg = 1000.0;

  String _vehicleType = '';
  String _kapasitas = '';
  String _bahanBakar = '';
  double _jarak = 0.0;
  String _fuelType = '';

  @override
  void initState() {
    super.initState();

    // ambil emisi dari HitungEmisiPage
    _sessionEmisi = widget.emisiKg > 0 ? widget.emisiKg : 0.0;

    _vehicleType = widget.vehicleType;
    _kapasitas = widget.kapasitas;
    _bahanBakar = widget.bahanBakar;
    _jarak = widget.jarak != 0.0 ? widget.jarak : widget.distanceKm;
    _fuelType = widget.fuelType;

    if (widget.hargaPerKg > 0) _hargaPerKg = widget.hargaPerKg;

    _loadLocalState();
  }

  Future<void> _loadLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // FIX: total emisi SELALU ambil dari SharedPreferences
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

      if (widget.emisiKg == 0.0) {
        final last = prefs.getDouble(_kLastSessionEmisi) ?? 0.0;
        if (last > 0) _sessionEmisi = last;
      }

      if (mounted) setState(() {});

    } catch (_) {}
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
      _vehicleType = '';
      _kapasitas = '';
      _bahanBakar = '';
      _fuelType = '';
      _jarak = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Total emisi berhasil di-reset."),
          backgroundColor: Colors.orange),
    );
  }

  Future<void> _createPayment() async {
    setState(() => isPaying = true);

    final emisiToPay = _sessionEmisi > 0 ? _sessionEmisi : _savedTotalEmisi;

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

  @override
  Widget build(BuildContext context) {
    final emisiDisplay = _sessionEmisi > 0 ? _sessionEmisi : _savedTotalEmisi;
    final totalPembayaran = (emisiDisplay * _hargaPerKg).round().toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text("Pembayaran Emisi",
            style: GoogleFonts.poppins(
                color: Colors.black87, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.red.shade600),
            onPressed: _resetAll,
            tooltip: "Reset Total Emisi",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // HEADER EMISI
            Container(
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
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 15),
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
            ),

            const SizedBox(height: 20),

            // RINGKASAN PEMBAYARAN
            Container(
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
                  _row("Emisi yg dibayar",
                      "${emisiDisplay.toStringAsFixed(3)} Kg"),
                  const Divider(height: 22),
                  _row("Konversi Emisi",
                      "Rp ${totalPembayaran.toStringAsFixed(0)}"),
                  const Divider(height: 22),
                  _row("Total Pembayaran",
                      "Rp ${totalPembayaran.toStringAsFixed(0)}",
                      bold: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // DETAIL KENDARAAN
            Container(
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
                  Text("Detail Kendaraan",
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  _row("Jenis Kendaraan",
                      _vehicleType.isEmpty ? "-" : _vehicleType),
                  _row("Kapasitas",
                      _kapasitas.isEmpty ? "-" : _kapasitas),
                  _row("Bahan Bakar",
                      _bahanBakar.isEmpty ? "-" : _bahanBakar),
                  _row("Jarak (km)", "${_jarak.toStringAsFixed(2)} km"),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // SIMPAN EMISI
            SizedBox(
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
                child: Text("SIMPAN EMISI",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
            ),

            const SizedBox(height: 12),

            // BAYAR SEKARANG
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPaying ? null : _createPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: isPaying
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text("BAYAR SEKARANG",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
            ),

            const SizedBox(height: 30),
          ],
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