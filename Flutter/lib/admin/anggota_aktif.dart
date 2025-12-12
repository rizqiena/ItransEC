import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';

class AnggotaAktifPage extends StatefulWidget {
  const AnggotaAktifPage({super.key});

  @override
  State<AnggotaAktifPage> createState() => _AnggotaAktifPageState();
}

class _AnggotaAktifPageState extends State<AnggotaAktifPage> {
  List<dynamic> anggotaAktif = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String errorMessage = '';
  
  // ✅ Pagination & Search
  int currentPage = 1;
  int lastPage = 1;
  int totalUser = 0;
  String searchQuery = '';
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ✅ Detect scroll to bottom untuk load more
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && currentPage < lastPage) {
        _loadMore();
      }
    }
  }

  // ✅ Load data pertama kali
  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        anggotaAktif.clear();
      });
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await ApiService.getMasyarakat(
      page: currentPage,
      perPage: 20,
      search: searchQuery,
    );

    setState(() {
      isLoading = false;
      if (result['status'] == true) {
        anggotaAktif = result['data'];
        totalUser = result['total'] ?? 0;
        currentPage = result['current_page'] ?? 1;
        lastPage = result['last_page'] ?? 1;
      } else {
        errorMessage = result['message'] ?? 'Gagal memuat data';
      }
    });
  }

  // ✅ Load more data (pagination)
  Future<void> _loadMore() async {
    if (isLoadingMore || currentPage >= lastPage) return;

    setState(() {
      isLoadingMore = true;
    });

    final result = await ApiService.getMasyarakat(
      page: currentPage + 1,
      perPage: 20,
      search: searchQuery,
    );

    setState(() {
      isLoadingMore = false;
      if (result['status'] == true) {
        anggotaAktif.addAll(result['data']);
        currentPage = result['current_page'] ?? currentPage;
        lastPage = result['last_page'] ?? lastPage;
      }
    });
  }

  // ✅ Search dengan debounce (tunggu 500ms setelah user selesai ketik)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = query;
        currentPage = 1;
        anggotaAktif.clear();
      });
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          "User Account",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(refresh: true),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🔵 Header biru dengan jumlah anggota
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "User Account",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isLoading ? "Loading..." : "$totalUser Orang",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // ✅ Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Cari nama atau email...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
              ),
            ),
          ),

          // 🔹 Daftar user
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _loadData(refresh: true),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : anggotaAktif.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'Belum ada user terdaftar'
                                      : 'Tidak ada hasil untuk "$searchQuery"',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadData(refresh: true),
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: anggotaAktif.length + (isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                // ✅ Loading indicator di bawah saat load more
                                if (index == anggotaAktif.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  );
                                }

                                final anggota = anggotaAktif[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.blueAccent,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              flex: 2,
                                              child: Text(
                                                anggota['Nama_Masyarakat'] ??
                                                    'Unknown',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              flex: 3,
                                              child: Text(
                                                anggota['Email_Masyarakat'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}