import 'package:flutter/material.dart';
import '../services/berita_services.dart';
import '../models/berita_model.dart';
import 'berita_form_page.dart';
import 'berita_detail_dialog.dart';

class BeritaAdminPage extends StatefulWidget {
  const BeritaAdminPage({super.key});

  @override
  State<BeritaAdminPage> createState() => _BeritaAdminPageState();
}

class _BeritaAdminPageState extends State<BeritaAdminPage> {
  List<Berita> _beritaList = [];
  BeritaPagination? _pagination;
  bool _isLoading = false;
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBerita();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🔄 Load Berita dari API
  Future<void> _loadBerita({int page = 1}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await BeritaService.getAllBerita(
        page: page,
        perPage: 10,
        search: _searchQuery,
      );

      if (result['status'] == true) {
        setState(() {
          _beritaList = result['data'] as List<Berita>;
          _pagination = result['pagination'] as BeritaPagination;
          _currentPage = page;
        });
      } else {
        _showSnackBar(result['message'] ?? 'Gagal memuat berita', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔍 Search Handler
  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadBerita(page: 1);
  }

  // ➕ Tambah Berita
  void _tambahBerita() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BeritaFormPage(),
      ),
    );

    if (result == true) {
      _loadBerita(page: _currentPage);
    }
  }

  // ✏️ Edit Berita
  void _editBerita(Berita berita) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BeritaFormPage(berita: berita),
      ),
    );

    if (result == true) {
      _loadBerita(page: _currentPage);
    }
  }

  // 🗑️ Hapus Berita
  void _hapusBerita(Berita berita) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus berita "${berita.judulBerita}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await BeritaService.deleteBerita(berita.idBerita);
      
      if (result['status'] == true) {
        _showSnackBar('Berita berhasil dihapus');
        _loadBerita(page: _currentPage);
      } else {
        _showSnackBar(result['message'] ?? 'Gagal menghapus berita', isError: true);
      }
    }
  }

  // 👁️ Lihat Detail
  void _lihatDetail(Berita berita) {
    showDialog(
      context: context,
      builder: (context) => BeritaDetailDialog(berita: berita),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Berita"),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBerita(page: _currentPage),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF2F5FA),
      body: RefreshIndicator(
        onRefresh: () => _loadBerita(page: _currentPage),
        child: Column(
          children: [
            // 🔍 Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari berita...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  if (value.isEmpty || value.length >= 3) {
                    _handleSearch(value);
                  }
                },
              ),
            ),

            // 📊 Stats Bar
            if (_pagination != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${_pagination!.total} berita',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      'Halaman ${_pagination!.currentPage} dari ${_pagination!.lastPage}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // 📰 List Berita
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _beritaList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _beritaList.length,
                          itemBuilder: (context, index) {
                            return _buildBeritaCard(_beritaList[index]);
                          },
                        ),
            ),

            // 🔢 Pagination
            if (_pagination != null && _pagination!.lastPage > 1)
              _buildPagination(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahBerita,
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Berita'),
      ),
    );
  }

  Widget _buildBeritaCard(Berita berita) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _lihatDetail(berita),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ Gambar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: berita.gambarBerita != null
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
                        fontSize: 16,
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
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          berita.tanggalBerita,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          berita.namaAdmin,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ⚙️ Action Buttons
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.blue,
                    onPressed: () => _editBerita(berita),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    onPressed: () => _hapusBerita(berita),
                  ),
                ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada berita',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan berita pertama Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => _loadBerita(page: _currentPage - 1)
                : null,
          ),
          Text(
            'Halaman $_currentPage dari ${_pagination!.lastPage}',
            style: const TextStyle(fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _pagination!.lastPage
                ? () => _loadBerita(page: _currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}