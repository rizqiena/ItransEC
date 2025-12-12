import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class EmisiHistoryPage extends StatefulWidget {
  const EmisiHistoryPage({super.key});

  @override
  State<EmisiHistoryPage> createState() => _EmisiHistoryPageState();
}

class _EmisiHistoryPageState extends State<EmisiHistoryPage> {
  late Future<List<dynamic>> futureEmisi;

  @override
  void initState() {
    super.initState();
    futureEmisi = _fetchEmisi();
  }

  Future<List<dynamic>> _fetchEmisi() async {
    try {
      final result = await ApiService.getUserEmission();
      return result;
    } catch (e) {
      debugPrint("❌ Error fetch emisi: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Riwayat Tebus Emisi",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureEmisi,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return Center(
              child: Text(
                "Belum ada data tebus emisi",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final d = data[i];

              final emisi = d['emisi'] ?? 0.0;
              final created = d['created_at'] ?? '-';
              final kendaraan = d['kendaraan'] ?? '-';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Emisi: ${emisi.toString()} kg CO₂",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text("Kendaraan: $kendaraan",
                        style: GoogleFonts.poppins(fontSize: 14)),
                    Text("Tanggal: $created",
                        style: GoogleFonts.poppins(fontSize: 14)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}