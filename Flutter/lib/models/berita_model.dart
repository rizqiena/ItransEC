import '../services/berita_services.dart';

class Berita {
  final int idBerita;
  final String judulBerita;
  final String deskripsiBerita;
  final String? gambarBerita;
  final String tanggalBerita;
  final String namaAdmin;
  final String createdAt;

  Berita({
    required this.idBerita,
    required this.judulBerita,
    required this.deskripsiBerita,
    this.gambarBerita,
    required this.tanggalBerita,
    required this.namaAdmin,
    required this.createdAt,
  });

  factory Berita.fromJson(Map<String, dynamic> json) {
    // ✅ Process gambar URL dengan helper dari BeritaService
    String? imageUrl = json['Gambar_Berita'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageUrl = BeritaService.getImageUrl(imageUrl);
    }

    return Berita(
      idBerita: json['Id_Berita'],
      judulBerita: json['Judul_Berita'],
      deskripsiBerita: json['Deskripsi_Berita'],
      gambarBerita: imageUrl, // ✅ Full URL
      tanggalBerita: json['Tanggal_Berita'],
      namaAdmin: json['Nama_Admin'] ?? 'Admin',
      createdAt: json['Created_At'],
    );
  }
}

class BeritaPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  BeritaPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory BeritaPagination.fromJson(Map<String, dynamic> json) {
    return BeritaPagination(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }
}