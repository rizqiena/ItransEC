// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.4:8000/api';

  // ========================
  // 🔐 AUTHENTICATION
  // ========================
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/masyarakat/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Nama_Masyarakat': username,
          'Email_Masyarakat': email,
          'KataSandi_Masyarakat': password,
          'KataSandi_Masyarakat_Confirmation': confirmPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginMasyarakat({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/masyarakat/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email_Masyarakat': email,
          'KataSandi_Masyarakat': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_type', 'masyarakat');
        await prefs.setString('user_data', jsonEncode(data['data']));
      }

      return data;
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email_Admin': email,
          'Password_Admin': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_type', 'admin');
        await prefs.setString('user_data', jsonEncode(data['data']));
      }

      return data;
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // ❗ FIXED LOGOUT (AMAN)
  // ========================
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      await prefs.remove('token');
      await prefs.remove('user_type');
      await prefs.remove('user_data');

      return true;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_type');
      await prefs.remove('user_data');
      return false;
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }

  // ========================
  // 👤 PROFILE MANAGEMENT
  // ========================
  static Future<Map<String, dynamic>> getProfil() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/masyarakat/profil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfil({
    required String nama,
    required String email,
    String? password,
    String? nomorHp,
    File? fotoProfil,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/masyarakat/profil/update'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['Nama_Masyarakat'] = nama;
      request.fields['Email_Masyarakat'] = email;
      request.fields['_method'] = 'PUT';

      if (password != null && password.isNotEmpty) {
        request.fields['KataSandi_Masyarakat'] = password;
      }

      if (nomorHp != null && nomorHp.isNotEmpty) {
        request.fields['No_Telp_Masyarakat'] = nomorHp;
      }

      if (fotoProfil != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Foto_Profil', fotoProfil.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        await prefs.setString('user_data', jsonEncode(data['data']));
      }

      return data;
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String passwordLama,
    required String passwordBaru,
    required String konfirmasiPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/masyarakat/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': passwordLama,
          'new_password': passwordBaru,
          'new_password_confirmation': konfirmasiPassword,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // 📊 DASHBOARD STATS
  // ========================
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // 📰 BERITA MANAGEMENT
  // ========================
  static Future<Map<String, dynamic>> getAllBerita() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/berita'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> getBeritaById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/berita/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

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
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/berita/store'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['Judul_Berita'] = judul;
      request.fields['Deskripsi_Berita'] = deskripsi;
      request.fields['Tanggal_Berita'] = tanggal;

      if (gambar != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Gambar_Berita', gambar.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

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
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/berita/$id/update'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['Judul_Berita'] = judul;
      request.fields['Deskripsi_Berita'] = deskripsi;
      request.fields['Tanggal_Berita'] = tanggal;
      request.fields['_method'] = 'PUT';

      if (gambar != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Gambar_Berita', gambar.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteBerita(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/berita/$id/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // 👥 PENERIMA MANAGEMENT
  // ========================
  static Future<Map<String, dynamic>> getAllPenerima() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/penerima'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> createPenerima({
    required String nama,
    required String alamat,
    required String noTelp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/penerima/store'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Nama_Penerima': nama,
          'Alamat_Penerima': alamat,
          'No_Telp_Penerima': noTelp,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePenerima({
    required int id,
    required String nama,
    required String alamat,
    required String noTelp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/admin/penerima/$id/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Nama_Penerima': nama,
          'Alamat_Penerima': alamat,
          'No_Telp_Penerima': noTelp,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> deletePenerima(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/penerima/$id/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // 👤 USER ACCOUNT MANAGEMENT
  // ========================
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMasyarakat({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('$baseUrl/admin/users').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$id/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // 🎁 PROGRAM DONASI
  // ========================
  static Future<Map<String, dynamic>> getAllProgramDonasi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/program-donasi'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProgramDonasiById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/program-donasi/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProgramDonasi({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('$baseUrl/admin/program-donasi').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> createProgramDonasi({
    required String judulProgram,
    required String namaPerusahaan,
    required String rekeningDonasi,
    required double targetDonasi,
    required String tanggalMulai,
    required String tanggalSelesai,
    double? emisiDonasi,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/program-donasi/store'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Judul_Program': judulProgram,
          'Nama_Perusahaan': namaPerusahaan,
          'Rekening_Donasi': rekeningDonasi,
          'Target_Donasi': targetDonasi,
          'Tanggal_Mulai_Donasi': tanggalMulai,
          'Tanggal_Selesai_Donasi': tanggalSelesai,
          'Emisi_Donasi': emisiDonasi ?? 0,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProgramDonasi({
    required int id,
    required String judulProgram,
    required String namaPerusahaan,
    required String rekeningDonasi,
    required double targetDonasi,
    required String tanggalMulai,
    required String tanggalSelesai,
    required double emisiDonasi,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/admin/program-donasi/$id/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Judul_Program': judulProgram,
          'Nama_Perusahaan': namaPerusahaan,
          'Rekening_Donasi': rekeningDonasi,
          'Target_Donasi': targetDonasi,
          'Tanggal_Mulai_Donasi': tanggalMulai,
          'Tanggal_Selesai_Donasi': tanggalSelesai,
          'Emisi_Donasi': emisiDonasi,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteProgramDonasi(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/program-donasi/$id/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // 🆕 PROGRAM DONASI AKTIF (FOR USER APP)
  // ========================

  /// 🆕 GET PROGRAM DONASI AKTIF - Digunakan di PaymentPage
  /// Endpoint: GET /api/programs/active
  static Future<Map<String, dynamic>> getProgramDonasiAktif() async {
    try {
      final url = Uri.parse('$baseUrl/programs/active');

      debugPrint('📡 [ApiService] Fetching active programs...');
      debugPrint('📡 [ApiService] GET: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📡 [ApiService] Response status: ${response.statusCode}');
      debugPrint('📡 [ApiService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message': 'Gagal memuat program: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ [ApiService] Error getProgramDonasiAktif: $e');
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  // ========================
  // 💳 PAYMENT SYSTEM (MIDTRANS)
  // ========================

  static double computeAmount(double emisiKg, double hargaPerKg) {
    return emisiKg * hargaPerKg;
  }

  /// 🆕 CREATE PAYMENT - UPDATED untuk support program_id & program_name
  /// Endpoint: POST /api/payment/create
  static Future<Map<String, dynamic>?> createPayment({
    required double amount,
    required double emisi,
    required String name,
    required String email,
    required String phone,
    int? programId, // 🆕 ADDED
    String? programName, // 🆕 ADDED
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final url = Uri.parse('$baseUrl/payment/create');

      final body = {
        'amount': amount,
        'emisi_kg': emisi,
        'customer_name': name,
        'customer_email': email,
        'customer_phone': phone,
        if (programId != null) 'program_id': programId, // 🆕
        if (programName != null) 'program_name': programName, // 🆕
      };

      debugPrint('📡 [ApiService] Creating payment...');
      debugPrint('📡 [ApiService] POST: $url');
      debugPrint('📡 Amount: $amount, Emisi: $emisi');
      debugPrint('📡 Program ID: $programId, Program Name: $programName');
      debugPrint('📡 Body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint('📡 [ApiService] Response status: ${response.statusCode}');
      debugPrint('📡 [ApiService] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('❌ [ApiService] Error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Gagal membuat payment: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ [ApiService] Exception createPayment: $e');
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'status': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/payment/status/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // 🌍 EMISI FEATURE
  // ========================
  static Future<Map<String, dynamic>> hitungEmisiKendaraan({
    required String jenisKendaraan,
    required double jarak,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emisi/kendaraan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jenis_kendaraan': jenisKendaraan,
          'jarak_km': jarak,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> hitungEmisiListrik({
    required double kwh,
    required int jumlahHari,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emisi/listrik'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kwh_perhari': kwh,
          'jumlah_hari': jumlahHari,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> hitungEmisiSampah({
    required double beratKg,
    required String jenisSampah,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emisi/sampah'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'berat_kg': beratKg,
          'jenis_sampah': jenisSampah,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // 📊 TEBUS EMISI - LOCAL STORAGE
  // ========================
  static Future<bool> saveEmisiData({
    required String kategori,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      List<String> existingData = prefs.getStringList('emisi_list') ?? [];

      Map<String, dynamic> newEntry = {
        'kategori': kategori,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      existingData.add(jsonEncode(newEntry));
      await prefs.setStringList('emisi_list', existingData);

      double totalEmisi = await getTotalEmisi();
      double newTotal = totalEmisi + (data['emisi_kg'] ?? 0.0);
      await prefs.setDouble('total_emisi', newTotal);

      return true;
    } catch (e) {
      debugPrint('Error saving emisi data: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getEmisiList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> data = prefs.getStringList('emisi_list') ?? [];

      return data.map((item) {
        return jsonDecode(item) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      debugPrint('Error getting emisi list: $e');
      return [];
    }
  }

  static Future<double> getTotalEmisi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('total_emisi') ?? 0.0;
    } catch (e) {
      debugPrint('Error getting total emisi: $e');
      return 0.0;
    }
  }

  static Future<bool> clearEmisiData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('emisi_list');
      await prefs.remove('total_emisi');
      return true;
    } catch (e) {
      debugPrint('Error clearing emisi data: $e');
      return false;
    }
  }

  static Future<bool> deleteEmisiItem(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> data = prefs.getStringList('emisi_list') ?? [];

      if (index >= 0 && index < data.length) {
        Map<String, dynamic> item = jsonDecode(data[index]);
        double emisiKg = item['data']['emisi_kg'] ?? 0.0;

        data.removeAt(index);
        await prefs.setStringList('emisi_list', data);

        double totalEmisi = await getTotalEmisi();
        double newTotal = totalEmisi - emisiKg;
        await prefs.setDouble('total_emisi', newTotal > 0 ? newTotal : 0);

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting emisi item: $e');
      return false;
    }
  }

  // ========================
  // 🆕 DONASI ADMIN FEATURES
  // ========================

  static Future<Map<String, dynamic>> getDonasiStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/donasi/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to get stats'};
    } catch (e) {
      debugPrint('Error get donasi stats: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDonasiList({
    int? programId,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (programId != null) queryParams['program_id'] = programId.toString();
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/admin/donasi/list').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to get list'};
    } catch (e) {
      debugPrint('Error get donasi list: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDonasiDetail(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/donasi/detail/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to get detail'};
    } catch (e) {
      debugPrint('Error get donasi detail: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> exportDonasi({
    String? startDate,
    String? endDate,
    int? programId,
    String? status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      Map<String, String> queryParams = {};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (programId != null) queryParams['program_id'] = programId.toString();
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/admin/donasi/export').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to export'};
    } catch (e) {
      debugPrint('Error export donasi: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // 🛠️ UTILITY METHODS
  // ========================

  static String formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  static String formatDateReadable(DateTime date) {
    const monthNames = [
      'Jan','Feb','Mar','Apr','Mei','Jun',
      'Jul','Agu','Sep','Okt','Nov','Des'
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  static String formatEmisi(double emisiKg) {
    return '${emisiKg.toStringAsFixed(2)} kg CO₂';
  }

  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'settlement':
      case 'success':
        return '#10B981';
      case 'pending':
        return '#F59E0B';
      case 'failed':
      case 'expired':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'settlement':
        return 'Berhasil';
      case 'success':
        return 'Berhasil';
      case 'pending':
        return 'Menunggu';
      case 'failed':
        return 'Gagal';
      case 'expired':
        return 'Kadaluarsa';
      default:
        return status;
    }
  }

  static String getProgramIcon(String programName) {
    final name = programName.toLowerCase();
    if (name.contains('pohon') || name.contains('penanaman')) {
      return '🌱';
    } else if (name.contains('energi') || name.contains('terbarukan')) {
      return '⚡';
    } else if (name.contains('hutan') || name.contains('konservasi')) {
      return '🌳';
    } else if (name.contains('sampah') || name.contains('daur')) {
      return '♻️';
    } else if (name.contains('air') || name.contains('sungai')) {
      return '💧';
    } else {
      return '🌍';
    }
  }

  static double calculateProgress(double current, double target) {
    if (target <= 0) return 0.0;
    double progress = (current / target) * 100;
    return progress > 100 ? 100.0 : progress;
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
        r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$'
    );
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(
        r'^(08|628|\+628)[0-9]{8,11}$'
    );
    return phoneRegex.hasMatch(phone);
  }

  static String cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('628')) {
      cleaned = '0${cleaned.substring(2)}';
    } else if (cleaned.startsWith('+628')) {
      cleaned = '0${cleaned.substring(3)}';
    }
    return cleaned;
  }

  static String getPaymentMethodIcon(String? method) {
    if (method == null) return '💳';
    final methodLower = method.toLowerCase();
    if (methodLower.contains('qris')) {
      return '📱';
    } else if (methodLower.contains('gopay')) {
      return '🟢';
    } else if (methodLower.contains('ovo')) {
      return '🟣';
    } else if (methodLower.contains('dana')) {
      return '🔵';
    } else if (methodLower.contains('bca')) {
      return '🏦';
    } else if (methodLower.contains('mandiri')) {
      return '🏦';
    } else if (methodLower.contains('bni')) {
      return '🏦';
    } else if (methodLower.contains('bri')) {
      return '🏦';
    } else {
      return '💳';
    }
  }

  static DateTime? parseTimestamp(String? timestamp) {
    if (timestamp == null) return null;
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      debugPrint('Error parsing timestamp: $e');
      return null;
    }
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun yang lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan yang lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // ========================
  // 🔍 DEBUG HELPER
  // ========================

  static void debugResponse(String method, String endpoint, dynamic response) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔍 API DEBUG: $method $endpoint');
      debugPrint('Response: ${jsonEncode(response)}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  static Future<bool> checkTokenValidity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/masyarakat/profil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking token validity: $e');
      return false;
    }
  }
}