import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/berita_model.dart';

class BeritaService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String imageBaseUrl = 'http://10.0.2.2:8000/storage/berita'; // ✅ Base URL untuk gambar

  // ✅ Helper untuk mendapatkan full image URL
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    
    // Jika sudah full URL, return langsung
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // Jika hanya nama file, gabungkan dengan base URL
    return '$imageBaseUrl/$imagePath';
  }

  // GET ALL BERITA (dengan pagination & search)
  static Future<Map<String, dynamic>> getAllBerita({
    int page = 1,
    int perPage = 10,
    String search = '',
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('$baseUrl/berita')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        List<Berita> beritas = (data['data'] as List)
            .map((item) => Berita.fromJson(item))
            .toList();

        return {
          'status': true,
          'data': beritas,
          'pagination': BeritaPagination.fromJson(data['pagination']),
        };
      }

      return data;
    } catch (e) {
      return {
        'status': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  // GET SINGLE BERITA
  static Future<Map<String, dynamic>> getBerita(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/berita/$id'));
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        return {
          'status': true,
          'data': Berita.fromJson(data['data']),
        };
      }

      return data;
    } catch (e) {
      return {
        'status': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  // ✅ GET TOTAL BERITA (untuk dashboard stats)
  static Future<Map<String, dynamic>> getTotalBerita() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/berita?per_page=1'),
      );
      final data = jsonDecode(response.body);

      if (data['status'] == true && data['pagination'] != null) {
        return {
          'status': true,
          'total': data['pagination']['total'] ?? 0,
        };
      }

      return {
        'status': false,
        'total': 0,
      };
    } catch (e) {
      return {
        'status': false,
        'total': 0,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  // ✅ GET LATEST BERITA (untuk tampilan di dashboard)
  static Future<Map<String, dynamic>> getLatestBerita({int limit = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/berita?per_page=$limit'),
      );
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        List<Berita> beritas = (data['data'] as List)
            .map((item) => Berita.fromJson(item))
            .toList();

        return {
          'status': true,
          'data': beritas,
        };
      }

      return data;
    } catch (e) {
      return {
        'status': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  // CREATE BERITA (Admin Only)
  static Future<Map<String, dynamic>> createBerita({
    required String judul,
    required String deskripsi,
    required String tanggal,
    File? gambar,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {
          'status': false,
          'message': 'Token tidak ditemukan',
        };
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/berita'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['Judul_Berita'] = judul;
      request.fields['Deskripsi_Berita'] = deskripsi;
      request.fields['Tanggal_Berita'] = tanggal;

      if (gambar != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'Gambar_Berita',
            gambar.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'status': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  // UPDATE BERITA (Admin Only)
  static Future<Map<String, dynamic>> updateBerita({
    required int id,
    required String judul,
    required String deskripsi,
    required String tanggal,
    File? gambar,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {
          'status': false,
          'message': 'Token tidak ditemukan',
        };
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/berita/$id'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['Judul_Berita'] = judul;
      request.fields['Deskripsi_Berita'] = deskripsi;
      request.fields['Tanggal_Berita'] = tanggal;

      if (gambar != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'Gambar_Berita',
            gambar.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'status': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  // DELETE BERITA (Admin Only)
  static Future<Map<String, dynamic>> deleteBerita(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {
          'status': false,
          'message': 'Token tidak ditemukan',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/berita/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'status': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }
}