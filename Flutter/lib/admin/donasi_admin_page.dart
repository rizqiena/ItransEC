import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DonasiAdminPage extends StatefulWidget {
  const DonasiAdminPage({super.key});

  @override
  State<DonasiAdminPage> createState() => _DonasiAdminPageState();
}

class _DonasiAdminPageState extends State<DonasiAdminPage> {
  List<Map<String, dynamic>> donasis = [];
  List<Map<String, dynamic>> filteredDonasis = [];
  bool isLoading = true;
  String? errorMessage;

  // Stats
  double totalDonasiHariIni = 0;
  int totalUserHariIni = 0;
  double totalEmisiHariIni = 0;
  double totalDonasiBulanIni = 0;

  // Filter
  String selectedProgram = 'Semua Program';
  String selectedStatus = 'Semua Status';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load stats
      print('📊 Loading donasi stats...');
      final statsResult = await ApiService.getDonasiStats();
      print('📥 Stats result: $statsResult');

      if (statsResult['success'] == true || statsResult['status'] == true) {
        final stats = statsResult['data'];
        if (stats != null) {
          setState(() {
            totalDonasiHariIni = _parseDouble(stats['today']?['total_donasi']);
            totalUserHariIni = _parseInt(stats['today']?['total_user']);
            totalEmisiHariIni = _parseDouble(stats['today']?['total_emisi']);
            totalDonasiBulanIni = _parseDouble(stats['this_month']?['total_donasi']);
          });
        }
      }

      // Load list donasi
      print('📋 Loading donasi list...');
      final listResult = await ApiService.getDonasiList();
      print('📥 List result: $listResult');

      if (listResult['success'] == true || listResult['status'] == true) {
        final data = listResult['data'];
        if (data != null) {
          if (data is List) {
            setState(() {
              donasis = List<Map<String, dynamic>>.from(data);
              filteredDonasis = donasis;
              isLoading = false;
            });
          } else if (data is Map && data['data'] is List) {
            setState(() {
              donasis = List<Map<String, dynamic>>.from(data['data']);
              filteredDonasis = donasis;
              isLoading = false;
            });
          } else {
            setState(() {
              donasis = [];
              filteredDonasis = [];
              isLoading = false;
            });
          }
        } else {
          setState(() {
            donasis = [];
            filteredDonasis = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = listResult['message'] ?? 'Gagal memuat data donasi';
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading donasi data: $e');
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredDonasis = donasis.where((donasi) {
        // Filter by program
        if (selectedProgram != 'Semua Program') {
          final programName = donasi['program_name'] ?? donasi['Judul_Program'] ?? '';
          if (!programName.toLowerCase().contains(selectedProgram.toLowerCase())) {
            return false;
          }
        }

        // Filter by status
        if (selectedStatus != 'Semua Status') {
          final status = donasi['payment_status'] ?? donasi['Status_Pembayaran'] ?? 'pending';
          if (selectedStatus == 'Success' && status != 'settlement' && status != 'success') {
            return false;
          }
          if (selectedStatus == 'Pending' && status != 'pending') {
            return false;
          }
          if (selectedStatus == 'Failed' && status != 'failed') {
            return false;
          }
        }

        // Filter by search
        if (searchQuery.isNotEmpty) {
          final userName = donasi['user_name'] ?? donasi['Nama_Masyarakat'] ?? '';
          final userEmail = donasi['user_email'] ?? donasi['Email_Masyarakat'] ?? '';
          if (!userName.toLowerCase().contains(searchQuery.toLowerCase()) &&
              !userEmail.toLowerCase().contains(searchQuery.toLowerCase())) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          '📊 Kelola Donasi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ FIXED: Stats Grid dengan childAspectRatio yang lebih baik
              _buildStatsGrid(),
              const SizedBox(height: 24),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 16),

              // Filter Chips
              _buildFilterChips(),
              const SizedBox(height: 16),

              // Content Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Donasi',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredDonasis.length} donasi',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Donation Cards
              if (filteredDonasis.isEmpty)
                _buildEmptyView()
              else
                ...filteredDonasis.map((donasi) => _buildDonationCard(donasi)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15, // ✅ FIXED: Ubah dari 1.4 ke 1.15 agar tidak overflow
      children: [
        _buildStatCard(
          'Donasi Hari Ini',
          'Rp ${_formatNumber(totalDonasiHariIni)}',
          Icons.payments_rounded,
          const Color(0xFF48BB78),
          const Color(0xFFC6F6D5),
        ),
        _buildStatCard(
          'User Hari Ini',
          '$totalUserHariIni User',
          Icons.people_rounded,
          const Color(0xFF4299E1),
          const Color(0xFFBEE3F8),
        ),
        _buildStatCard(
          'Emisi Ditebus',
          '${totalEmisiHariIni.toStringAsFixed(1)} kg',
          Icons.eco_rounded,
          const Color(0xFF9F7AEA),
          const Color(0xFFE9D8FD),
        ),
        _buildStatCard(
          'Bulan Ini',
          'Rp ${_formatNumber(totalDonasiBulanIni)}',
          Icons.trending_up_rounded,
          const Color(0xFFED8936),
          const Color(0xFFFEEBC8),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color,
      Color bgColor,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Colored top border
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12), // ✅ FIXED: Kurangi padding dari 16 ke 12
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8), // ✅ FIXED: Kurangi padding dari 10 ke 8
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22), // ✅ FIXED: Kurangi size dari 24 ke 22
                ),
                const SizedBox(height: 8), // ✅ FIXED: Kurangi dari 12 ke 8
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11, // ✅ FIXED: Kurangi dari 12 ke 11
                    color: const Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // ✅ FIXED: Kurangi dari 4 ke 2
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16, // ✅ FIXED: Kurangi dari 20 ke 16
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: '🔍 Cari nama atau email user...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFFA0AEC0),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          label: selectedProgram,
          icon: Icons.category_outlined,
          onTap: () => _showProgramFilter(),
        ),
        _buildFilterChip(
          label: selectedStatus,
          icon: Icons.check_circle_outline,
          onTap: () => _showStatusFilter(),
        ),
        if (selectedProgram != 'Semua Program' || selectedStatus != 'Semua Status')
          _buildFilterChip(
            label: 'Reset Filter',
            icon: Icons.clear,
            isReset: true,
            onTap: () {
              setState(() {
                selectedProgram = 'Semua Program';
                selectedStatus = 'Semua Status';
              });
              _applyFilters();
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isReset = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isReset ? const Color(0xFFFEEBC8) : Colors.white,
          border: Border.all(
            color: isReset ? const Color(0xFFED8936) : const Color(0xFFE2E8F0),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isReset ? const Color(0xFFED8936) : const Color(0xFF4A5568),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isReset ? const Color(0xFFED8936) : const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donasi) {
    final userName = donasi['user_name'] ?? donasi['Nama_Masyarakat'] ?? 'Unknown';
    final userEmail = donasi['user_email'] ?? donasi['Email_Masyarakat'] ?? '';
    final userPhone = donasi['user_phone'] ?? donasi['No_Hp_Masyarakat'] ?? '';
    final emisiKg = _parseDouble(donasi['emisi_kg'] ?? donasi['Emisi_Kg']);
    final nominal = _parseDouble(donasi['nominal_donasi'] ?? donasi['Nominal_Donasi']);
    final programName = donasi['program_name'] ?? donasi['Judul_Program'] ?? 'Program Donasi';
    final paymentMethod = donasi['payment_method'] ?? donasi['Payment_Method'] ?? 'Unknown';
    final status = donasi['payment_status'] ?? donasi['Status_Pembayaran'] ?? 'pending';
    final transactionId = donasi['transaction_id'] ?? donasi['Order_Id'] ?? '-';
    final createdAt = donasi['created_at'] ?? DateTime.now().toString();

    // Parse date
    DateTime date;
    try {
      date = DateTime.parse(createdAt);
    } catch (e) {
      date = DateTime.now();
    }

    // Status badge
    Color statusColor;
    String statusText;
    IconData statusIcon;
    if (status == 'settlement' || status == 'success') {
      statusColor = const Color(0xFF48BB78);
      statusText = 'Success';
      statusIcon = Icons.check_circle;
    } else if (status == 'pending') {
      statusColor = const Color(0xFFED8936);
      statusText = 'Pending';
      statusIcon = Icons.access_time;
    } else {
      statusColor = const Color(0xFFF56565);
      statusText = 'Failed';
      statusIcon = Icons.cancel;
    }

    // Program emoji
    String programEmoji = '🌱';
    if (programName.toLowerCase().contains('energi')) {
      programEmoji = '⚡';
    } else if (programName.toLowerCase().contains('hutan')) {
      programEmoji = '🌳';
    } else if (programName.toLowerCase().contains('sampah')) {
      programEmoji = '♻️';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      if (userEmail.isNotEmpty)
                        Text(
                          '📧 $userEmail',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      if (userPhone.isNotEmpty)
                        Text(
                          '📱 $userPhone',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF718096),
                          ),
                        ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        emoji: '🌍',
                        label: 'Emisi Ditebus',
                        value: '${emisiKg.toStringAsFixed(2)} kg CO₂',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailItem(
                        emoji: '💰',
                        label: 'Nominal Donasi',
                        value: 'Rp ${_formatNumber(nominal)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        emoji: programEmoji,
                        label: 'Program',
                        value: programName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailItem(
                        emoji: '💳',
                        label: 'Metode',
                        value: paymentMethod,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '📅 ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date)} | 🆔 $transactionId',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF718096),
                    ),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _showDetailDialog(donasi),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Detail',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String emoji,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF718096),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFF56565),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada donasi',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Donasi akan muncul di sini setelah user melakukan tebus emisi',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFFA0AEC0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProgramFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Program',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['Semua Program', 'Penanaman Pohon', 'Energi Terbarukan', 'Konservasi Hutan', 'Pengelolaan Sampah']
                .map((program) => ListTile(
              title: Text(program),
              trailing: selectedProgram == program
                  ? const Icon(Icons.check_circle, color: Color(0xFF48BB78))
                  : null,
              onTap: () {
                setState(() {
                  selectedProgram = program;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['Semua Status', 'Success', 'Pending', 'Failed']
                .map((status) => ListTile(
              title: Text(status),
              trailing: selectedStatus == status
                  ? const Icon(Icons.check_circle, color: Color(0xFF48BB78))
                  : null,
              onTap: () {
                setState(() {
                  selectedStatus = status;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter & Export',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.category_outlined, color: Color(0xFF667EEA)),
              title: const Text('Filter Program'),
              onTap: () {
                Navigator.pop(context);
                _showProgramFilter();
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF48BB78)),
              title: const Text('Filter Status'),
              onTap: () {
                Navigator.pop(context);
                _showStatusFilter();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_download_outlined, color: Color(0xFFED8936)),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                _showExportOptions();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Color(0xFF48BB78)),
              title: const Text('Export ke Excel'),
              subtitle: const Text('Format .xlsx'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export Excel akan segera tersedia')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Color(0xFF4299E1)),
              title: const Text('Export ke CSV'),
              subtitle: const Text('Format .csv'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export CSV akan segera tersedia')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFF56565)),
              title: const Text('Export ke PDF'),
              subtitle: const Text('Laporan lengkap'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export PDF akan segera tersedia')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> donasi) {
    final userName = donasi['user_name'] ?? donasi['Nama_Masyarakat'] ?? 'Unknown';
    final userEmail = donasi['user_email'] ?? donasi['Email_Masyarakat'] ?? '';
    final userPhone = donasi['user_phone'] ?? donasi['No_Hp_Masyarakat'] ?? '';
    final userId = donasi['user_id'] ?? donasi['Id_Masyarakat'] ?? '-';
    final emisiKg = _parseDouble(donasi['emisi_kg'] ?? donasi['Emisi_Kg']);
    final nominal = _parseDouble(donasi['nominal_donasi'] ?? donasi['Nominal_Donasi']);
    final programName = donasi['program_name'] ?? donasi['Judul_Program'] ?? 'Program Donasi';
    final paymentMethod = donasi['payment_method'] ?? donasi['Payment_Method'] ?? 'Unknown';
    final status = donasi['payment_status'] ?? donasi['Status_Pembayaran'] ?? 'pending';
    final transactionId = donasi['transaction_id'] ?? donasi['Order_Id'] ?? '-';
    final midtransOrderId = donasi['midtrans_order_id'] ?? donasi['Order_Id'] ?? '-';
    final createdAt = donasi['created_at'] ?? DateTime.now().toString();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '📄 Detail Donasi\n#$transactionId',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection('Informasi User', [
                        {'Nama': userName},
                        {'Email': userEmail},
                        {'No. HP': userPhone},
                        {'User ID': '#$userId'},
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoSection('Informasi Donasi', [
                        {'Emisi Ditebus': '${emisiKg.toStringAsFixed(2)} kg CO₂'},
                        {'Nominal Donasi': 'Rp ${_formatNumber(nominal)}'},
                        {'Rate': 'Rp 1.000/kg'},
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoSection('Informasi Program', [
                        {'Program': programName},
                        {'Target': '-'},
                        {'Progress': '-'},
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoSection('Informasi Payment', [
                        {'Metode': paymentMethod},
                        {'Status': status},
                        {'Transaction ID': transactionId},
                        {'Midtrans Order ID': midtransOrderId},
                        {'Payment Time': createdAt},
                      ]),
                    ],
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2E8F0),
                        foregroundColor: const Color(0xFF4A5568),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: items.map((item) {
              final key = item.keys.first;
              final value = item.values.first;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      key,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF718096),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    return NumberFormat('#,###', 'id_ID').format(number);
  }
}