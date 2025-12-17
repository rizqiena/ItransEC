import 'package:flutter/material.dart';
import '../models/berita_model.dart';

class BeritaDetailDialog extends StatelessWidget {
  final Berita berita;

  const BeritaDetailDialog({super.key, required this.berita});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🖼️ Header dengan Gambar
            if (berita.gambarBerita != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  berita.gambarBerita!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.grey[500],
                      ),
                    );
                  },
                ),
              ),

            // 📝 Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Text(
                      berita.judulBerita,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Meta Info
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          berita.tanggalBerita,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          berita.namaAdmin,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Deskripsi
                    Text(
                      berita.deskripsiBerita,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Created At
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Dibuat: ${berita.createdAt}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ❌ Close Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}