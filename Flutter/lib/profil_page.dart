// lib/profil_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_profil.dart';
import 'riwayat_page.dart';
import 'services/api_service.dart';
import 'login_page.dart';
import 'widgets/emission_limit_section.dart';
import 'payment_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String nama = "";
  String email = "";
  String? noHp;
  String? fotoProfil;
  bool isLoading = true;
  double totalEmisi = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfil();
    _loadTotalEmisi();
  }

  // ============================
  // LOAD PROFIL USER
  // ============================
  Future<void> _loadProfil() async {
    setState(() => isLoading = true);

    final result = await ApiService.getProfil();

    if (!mounted) return;

    setState(() {
      isLoading = false;

      if (result['status'] == true) {
        final data = result['data'];
        nama = data['Nama_Masyarakat'] ?? '';
        email = data['Email_Masyarakat'] ?? '';
        noHp = data['Nomor_HP'];
        fotoProfil = data['Profil_Masyarakat'];
      }
    });
  }

  // ============================
  // LOAD TOTAL EMISI
  // ============================
  Future<void> _loadTotalEmisi() async {
    final prefs = await SharedPreferences.getInstance();
    final emisi = prefs.getDouble('total_emisi') ?? 0.0;

    print("🔄 [ProfilPage] Load Total Emisi: ${emisi.toStringAsFixed(3)} kg");

    if (mounted) {
      setState(() {
        totalEmisi = emisi;
      });
    }
  }

  // ====================================================
  // CLEAR EMISI — FIX PENTING: Hapus SEMUA saat logout
  // ====================================================
  Future<void> _clearEmissionData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('total_emisi');
    await prefs.remove('last_session_emisi');
    await prefs.remove('saved_harga_kg');
    await prefs.remove('saved_jarak');
    await prefs.remove('saved_vehicle');
    await prefs.remove('saved_kapasitas');
    await prefs.remove('saved_bahan_bakar');
    await prefs.remove('saved_fueltype');
    await prefs.remove('history_tebus_emisi');

    print("🧹 Semua data emisi berhasil dihapus saat logout.");
  }

  // ============================
  // LOGOUT CONFIRM
  // ============================
  Future<void> _showLogoutConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _clearEmissionData();
      await ApiService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  // ========================================================
  // NAVIGATE TO TEBUS EMISI - FIX: RELOAD DATA SEBELUM NAVIGASI
  // ========================================================
  Future<void> _navigateToTebusEmisi() async {
    // ✅ FIX: Reload total emisi SEBELUM masuk ke PaymentPage
    print("🔄 [ProfilPage] Reload data emisi sebelum masuk Tebus Emisi...");
    await _loadTotalEmisi();

    // Delay kecil untuk memastikan SharedPreferences ter-update
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Navigasi ke payment page dengan mode Tebus Emisi
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PaymentPage(
          hargaPerKg: 1000.0,
          isTebusEmisi: true,
        ),
      ),
    );

    // Refresh data setelah kembali dari payment
    if (result == true) {
      print("✅ [ProfilPage] Kembali dari PaymentPage, reload data...");
      await _loadTotalEmisi();
    }
  }

  bool get isProfilLengkap => noHp != null && noHp!.isNotEmpty;

  // ============================
  // BUILD UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Profil"),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadProfil();
              await _loadTotalEmisi();
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await _loadProfil();
          await _loadTotalEmisi();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ============================
              // ALERT PROFIL BELUM LENGKAP
              // ============================
              if (!isProfilLengkap)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profil Belum Lengkap',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Lengkapi nomor HP Anda',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ============================
              // FOTO PROFIL
              // ============================
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: fotoProfil != null
                      ? NetworkImage(fotoProfil!)
                      : null,
                  onBackgroundImageError: fotoProfil != null
                      ? (_, __) => print("❌ Foto gagal dimuat")
                      : null,
                  child: fotoProfil == null
                      ? Icon(Icons.person,
                      size: 60, color: Colors.grey.shade400)
                      : null,
                ),
              ),

              const SizedBox(height: 15),

              Text(nama,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(email, style: TextStyle(color: Colors.grey[700])),

              const SizedBox(height: 20),

              // ============================
              // CARD INFORMASI
              // ============================
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _infoItem(Icons.person, "Nama", nama),
                    const Divider(thickness: 0.8, height: 20),
                    _infoItem(Icons.email, "Email", email),
                    const Divider(thickness: 0.8, height: 20),
                    _infoItem(Icons.phone, "Nomor HP",
                        noHp ?? "Belum diisi"),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ============================
              // LIMIT EMISI
              // ============================
              const EmissionLimitSection(),

              const SizedBox(height: 20),

              // ============================
              // MENU RIWAYAT
              // ============================
              _menuItem(Icons.history, "Riwayat", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RiwayatPage()),
                );
              }),

              // ============================
              // MENU TEBUS EMISI (FULL PAGE)
              // ============================
              _menuItem(
                Icons.credit_card,
                "Tebus Emisi",
                _navigateToTebusEmisi,
                subtitle: "Kompensasi jejak karbonmu",
              ),

              // ============================
              // MENU EDIT PROFIL
              // ============================
              _menuItem(Icons.edit, "Edit Profil", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilPage(
                      nama: nama,
                      email: email,
                      noHp: noHp ?? '',
                      fotoProfil: fotoProfil ?? '',
                    ),
                  ),
                ).then((_) {
                  // Refresh setelah edit profil
                  _loadProfil();
                });
              }),

              const Divider(height: 40),

              // ============================
              // LOGOUT
              // ============================
              ListTile(
                leading:
                const Icon(Icons.logout, color: Color(0xFFF44336)),
                title: const Text(
                  "Log out",
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 16),
                ),
                trailing:
                const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: _showLogoutConfirmation,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================
  // KOMPONEN: INFO ITEM
  // ============================
  Widget _infoItem(IconData icon, String title, String value) {
    final isEmpty = value == "Belum diisi";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: isEmpty ? Colors.orange : Colors.black87,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // KOMPONEN: MENU ITEM
  // ============================
  Widget _menuItem(
      IconData icon,
      String title,
      VoidCallback onTap, {
        String? subtitle,
      }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }
}