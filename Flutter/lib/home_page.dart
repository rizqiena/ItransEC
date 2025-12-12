import 'dart:ui';
import 'package:flutter/material.dart';
import 'profil_page.dart';
import 'hitung_emisi_page.dart';
import 'trip_simulation_page.dart';
import 'services/api_service.dart';
import 'services/berita_services.dart';
import 'models/berita_model.dart';
import 'admin/berita_detail_dialog.dart';
import 'services/emission_settings.dart';
import 'services/emission_api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const BerandaPage(),
    const HitungEmisiPage(),
    const SimulasiPage(),
    const ProfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF4CAF50),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Hitung Emisi'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Simulasi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  bool isProfilLengkap = true;
  bool isLoading = true;
  List<Berita> beritaList = [];
  bool isLoadingBerita = true;

  // state untuk card emisi
  double _totalEmissionThisMonth = 0.0;
  double? _monthlyLimit;
  bool _isLoadingEmissionCard = true;

  @override
  void initState() {
    super.initState();
    _checkProfil();
    _loadBerita();
    _loadEmissionCardData();
  }

  Future<void> _checkProfil() async {
    setState(() => isLoading = true);
    final result = await ApiService.getProfil();
    if (mounted) {
      setState(() {
        isLoading = false;
        if (result['status'] == true) {
          final data = result['data'];
          final noHp = data['Nomor_HP'];
          isProfilLengkap = noHp != null && noHp.toString().isNotEmpty;
        }
      });
    }
  }

  Future<void> _loadBerita() async {
    setState(() => isLoadingBerita = true);
    final result = await BeritaService.getLatestBerita(limit: 6);
    if (mounted) {
      setState(() {
        isLoadingBerita = false;
        if (result['status'] == true) {
          beritaList = result['data'] as List<Berita>;
        }
      });
    }
  }

  // load batas emisi + total emisi bulan ini dari backend
  Future<void> _loadEmissionCardData() async {
    setState(() {
      _isLoadingEmissionCard = true;
    });

    final limit = await EmissionSettings.getMonthlyLimit();

    double total = 0.0;
    try {
      total = await EmissionApi.getMonthlyTotal();
    } catch (e) {
      // ignore: avoid_print
      print('Error load monthly emission: $e');
      total = 0.0;
    }

    if (!mounted) return;

    setState(() {
      _monthlyLimit = limit;
      _totalEmissionThisMonth = total;
      _isLoadingEmissionCard = false;
    });
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _checkProfil(),
      _loadBerita(),
      _loadEmissionCardData(),
    ]);
  }

  void _showBeritaDetail(Berita berita) {
    showDialog(
      context: context,
      builder: (context) => BeritaDetailDialog(berita: berita),
    );
  }

  void _showArtikelPopup(BuildContext context, Map<String, String> artikel) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/splash/logo.png',
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 180,
                          color: const Color(0xFF4CAF50),
                          child: const Icon(Icons.eco, size: 80, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artikel["judul"]!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B4332),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            artikel["konten"]!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _getArtikelLengkap(artikel["judul"]!),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          "Tutup",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getArtikelLengkap(String judul) {
    switch (judul) {
      case "5 Cara Mudah Kurangi Jejak Karbon Harianmu":
        return "Untuk mengurangi jejak karbon, kamu bisa memulai dengan hal-hal sederhana. Pertama, gunakan transportasi umum atau bersepeda untuk aktivitas sehari-hari. Kedua, kurangi penggunaan plastik sekali pakai dengan membawa tas belanja dan botol minum sendiri.\n\nKetiga, matikan peralatan elektronik saat tidak digunakan untuk menghemat energi. Keempat, kurangi konsumsi daging merah dan perbanyak sayuran. Kelima, dukung produk lokal untuk mengurangi emisi dari transportasi jarak jauh.";
      case "Kenapa Emisi Karbon Itu Penting?":
        return "Emisi CO₂ menyebabkan efek rumah kaca yang memicu perubahan iklim. Dampaknya meliputi pencairan es kutub, naiknya permukaan air laut, dan cuaca ekstrem. Mengurangi emisi memperlambat laju perubahan iklim.";
      case "Tips Gaya Hidup Hijau untuk Pemula":
        return "Mulai dari hemat energi (lampu LED, cabut charger), kurangi sampah (3R), belanja produk lokal, dan pilah sampah/kompos.";
      case "Transportasi Ramah Lingkungan":
        return "Untuk jarak dekat, jalan kaki/bersepeda. Untuk jarak menengah, pakai angkutan umum. Jika harus naik kendaraan pribadi, pertimbangkan carpooling atau EV.";
      default:
        return "Baca artikel lengkapnya untuk detail lebih jauh.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> artikelList = [
      {
        "judul": "5 Cara Mudah Kurangi Jejak Karbon Harianmu",
        "konten": "Transportasi umum, kurangi plastik, dan hemat energi.",
      },
      {
        "judul": "Kenapa Emisi Karbon Itu Penting?",
        "konten": "Emisi karbon mempengaruhi perubahan iklim global.",
      },
      {
        "judul": "Tips Gaya Hidup Hijau untuk Pemula",
        "konten": "Mulai dari hemat listrik sampai pilih produk lokal.",
      },
      {
        "judul": "Transportasi Ramah Lingkungan",
        "konten": "Jalan kaki/sepeda untuk dekat, angkutan umum untuk jauh.",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isLoading && !isProfilLengkap)
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
                        const Icon(Icons.info_outline, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Profil Belum Lengkap',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Lengkapi nomor HP Anda untuk pengalaman lebih baik',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              (context.findAncestorStateOfType<_HomePageState>())?._onItemTapped(3),
                          child: const Text(
                            'Lengkapi',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Text(
                  "Welcome!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Yuk, pantau dan kurangi emisi kamu tiap hari 🌱",
                  style: TextStyle(fontSize: 15, color: Color(0xFF2D6A4F)),
                ),
                const SizedBox(height: 20),

                // Card total emisi bulan ini
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isLoadingEmissionCard
                      ? const SizedBox(
                          height: 60,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Emisi Bulan Ini",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${_totalEmissionThisMonth.toStringAsFixed(1)} Kg",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    "CO₂",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (_monthlyLimit != null && _monthlyLimit! > 0)
                                    ? (_totalEmissionThisMonth / _monthlyLimit!)
                                        .clamp(0.0, 1.0)
                                        .toDouble()
                                    : 0.0,
                                backgroundColor: const Color(0xFFE5F2E9),
                                color: const Color(0xFF4CAF50),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _monthlyLimit != null
                                  ? "Batas bulan ini: ${_monthlyLimit!.toStringAsFixed(1)} Kg CO₂"
                                  : "Batas emisi belum diatur",
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.eco, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Kamu menghemat emisi di bulan ini, kerja bagus!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Terus pertahankan gaya hidup ramah lingkunganmu!",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          "Lihat Tips",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                      elevation: 0,
                    ),
                    onPressed: () =>
                        (context.findAncestorStateOfType<_HomePageState>())?._onItemTapped(1),
                    child: const Text(
                      "Mulai Perjalanan Baru",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Berita Terkini",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    if (!isLoadingBerita && beritaList.isNotEmpty)
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoadingBerita)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                    ),
                  )
                else if (beritaList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.article_outlined, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada berita',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: beritaList.map((berita) {
                      return GestureDetector(
                        onTap: () => _showBeritaDetail(berita),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                                child: berita.gambarBerita != null &&
                                        berita.gambarBerita!.isNotEmpty
                                    ? Image.network(
                                        berita.gambarBerita!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.image,
                                            size: 40,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.image,
                                          size: 40,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        berita.judulBerita,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        berita.deskripsiBerita,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 11,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            berita.tanggalBerita,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),
                const Text(
                  "Artikel Terbaru",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: artikelList.map((artikel) {
                    return GestureDetector(
                      onTap: () => _showArtikelPopup(context, artikel),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: Image.asset(
                                'assets/splash/logo.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 80,
                                  height: 80,
                                  color: const Color(0xFF4CAF50),
                                  child: const Icon(
                                    Icons.article,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artikel["judul"]!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      artikel["konten"]!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SimulasiPage extends StatelessWidget {
  const SimulasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TripSimWithMapPage();
  }
}
