// lib/profile_page.dart

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

  @override
  void initState() {
    super.initState();
    _loadProfil();
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
            onPressed: _loadProfil,
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProfil,
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
              // MENU TEBUS EMISI
              // ============================
              _menuItem(Icons.credit_card, "Tebus Emisi", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentPage(),
                  ),
                );
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
  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(title,
          style:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }
}