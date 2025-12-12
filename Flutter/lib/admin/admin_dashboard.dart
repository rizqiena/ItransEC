import 'package:flutter/material.dart';
import '../admin/kelola_penerima_page.dart';
import 'berita_admin.dart';
import 'anggota_aktif.dart';
import '../login_page.dart';
import '../services/api_service.dart';
import '../services/berita_services.dart';
import '../models/berita_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ✅ Dashboard stats dari database
  int totalUser = 0;
  int totalBerita = 0; // ✅ Real data dari API
  int totalPenerima = 0; // ✅ Real data dari API
  bool isLoadingStats = true;

  // ✅ Latest berita untuk ditampilkan di dashboard
  List<Berita> latestBerita = [];
  bool isLoadingBerita = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
    _loadLatestBerita();
  }

  // ✅ Load stats dari API
  Future<void> _loadDashboardStats() async {
    setState(() {
      isLoadingStats = true;
    });

    final result = await ApiService.getDashboardStats();

    if (mounted) {
      setState(() {
        isLoadingStats = false;
        if (result['status'] == true) {
          totalUser = result['data']['total_user'] ?? 0;
          totalBerita = result['data']['total_berita'] ?? 0; // ✅ Real data
          totalPenerima = result['data']['total_penerima'] ?? 0; // ✅ Real data
        }
      });
    }
  }

  // ✅ Load latest berita
  Future<void> _loadLatestBerita() async {
    setState(() {
      isLoadingBerita = true;
    });

    final result = await BeritaService.getLatestBerita(limit: 5);

    if (mounted) {
      setState(() {
        isLoadingBerita = false;
        if (result['status'] == true) {
          latestBerita = result['data'] as List<Berita>;
        }
      });
    }
  }

  // ✅ Refresh All Data
  Future<void> _refreshAll() async {
    await Future.wait([
      _loadDashboardStats(),
      _loadLatestBerita(),
    ]);
  }

  // ✅ Logout dengan konfirmasi
  Future<void> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ApiService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),

      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  CircleAvatar(
                    backgroundColor: Color(0xFF4CAF50),
                    radius: 24,
                    child: Icon(Icons.eco_rounded, color: Colors.white, size: 26),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "I-TransEC Admin",
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: Color(0xFF4CAF50)),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.article_rounded, color: Colors.black54),
              title: const Text("Berita"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BeritaAdminPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism_rounded, color: Colors.black54),
              title: const Text("Penerima"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KelolaPenerimaPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded, color: Colors.black54),
              title: const Text("User Acc"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnggotaAktifPage()),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text("Keluar", style: TextStyle(color: Colors.redAccent)),
              onTap: _showLogoutConfirmation,
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Dashboard Admin",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Selamat datang kembali, Admin 👋",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Kelola aktivitas I-TransEC dengan mudah di sini",
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              // ✅ Stats Cards (Real-time dari database)
              if (isLoadingStats)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: PressableScale(
                        onTap: () {
                          Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const BeritaAdminPage()));
                        },
                        child: _statCard(
                          icon: Icons.newspaper_rounded,
                          label: "Berita",
                          count: totalBerita.toString(), // ✅ Real data!
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PressableScale(
                        onTap: () {
                          Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const KelolaPenerimaPage()));
                        },
                        child: _statCard(
                          icon: Icons.volunteer_activism_rounded,
                          label: "Penerima",
                          count: totalPenerima.toString(), // ✅ Real data!
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ),
                    Expanded(
                      child: PressableScale(
                        onTap: () {
                          Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AnggotaAktifPage()));
                        },
                        child: _statCard(
                          icon: Icons.people_alt_rounded,
                          label: "User Acc",
                          count: totalUser.toString(), // ✅ Real data!
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 35),

              // ✅ Latest Berita Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Berita Terbaru",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BeritaAdminPage()),
                      );
                    },
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // ✅ Berita List
              if (isLoadingBerita)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (latestBerita.isEmpty)
                _buildEmptyBerita()
              else
                ...latestBerita.map((berita) => _buildBeritaCard(berita)),

              const SizedBox(height: 35),
              const Text(
                "Menu Utama",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 15),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  PressableScale(
                    onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BeritaAdminPage()));
                    },
                    child: _menuCard(
                      icon: Icons.newspaper_rounded,
                      title: "Edit Berita",
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  PressableScale(
                    onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const KelolaPenerimaPage()));
                    },
                    child: _menuCard(
                      icon: Icons.volunteer_activism_rounded,
                      title: "Kelola Penerima",
                      color: Colors.orangeAccent,
                    ),
                  ),
                  PressableScale(
                    onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AnggotaAktifPage()));
                    },
                    child: _menuCard(
                      icon: Icons.people_alt_rounded,
                      title: "User Acc",
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Berita Card Widget
  Widget _buildBeritaCard(Berita berita) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BeritaAdminPage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ Gambar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: berita.gambarBerita != null && berita.gambarBerita!.isNotEmpty
                    ? Image.network(
                        berita.gambarBerita!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),

              // 📝 Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      berita.judulBerita,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      berita.deskripsiBerita,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          berita.tanggalBerita,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: Icon(Icons.image, size: 40, color: Colors.grey[500]),
    );
  }

  Widget _buildEmptyBerita() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.article_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Belum ada berita',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 30,
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  double _scale = 1.0;

  void _pressDown() => setState(() => _scale = 0.92);
  void _pressUp() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _pressDown(),
      onPointerUp: (_) => _pressUp(),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}