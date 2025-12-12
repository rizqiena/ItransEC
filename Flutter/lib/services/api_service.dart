// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

      // FIX: Jangan hapus data emisi!
      await prefs.remove('token');
      await prefs.remove('user_type');
      await prefs.remove('user_data');

      return true;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();

      // Tetap hanya hapus data login
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
        Uri.parse('$baseUrl/masyarakat/profil'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['Nama_Masyarakat'] = nama;
      request.fields['Email_Masyarakat'] = email;

      if (nomorHp != null && nomorHp.isNotEmpty) {
        request.fields['Nomor_HP'] = nomorHp;
      }

      if (fotoProfil != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'foto_profil',
          fotoProfil.path,
        ));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      return jsonDecode(response.body);
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
          'password_lama': passwordLama,
          'password_baru': passwordBaru,
          'konfirmasi_password': konfirmasiPassword,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========================
  // 📊 ADMIN DASHBOARD
  // ========================
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return {'status': false, 'message': 'Token tidak ditemukan'};

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
  // 👥 MASYARAKAT MANAGEMENT
  // ========================
  static Future<Map<String, dynamic>> getMasyarakat({
    int page = 1,
    int perPage = 20,
    String search = '',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return {'status': false, 'message': 'Token tidak ditemukan'};

      final uri = Uri.parse('$baseUrl/admin/masyarakat').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
          if (search.isNotEmpty) 'search': search,
        },
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

  // ========================
  // 💰 PROGRAM DONASI
  // ========================
  static Future<Map<String, dynamic>> getProgramDonasi({
    int page = 1,
    int perPage = 20,
    String search = '',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return {'status': false, 'message': 'Token tidak ditemukan'};

      final uri = Uri.parse('$baseUrl/admin/program-donasi').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
          if (search.isNotEmpty) 'search': search,
        },
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

  static Future<Map<String, dynamic>> createProgramDonasi({
    required String judulProgram,
    required String namaPerusahaan,
    required String rekeningDonasi,
    required double targetDonasi,
    required String tanggalMulai,
    required String tanggalSelesai,
    double emisiDonasi = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return {'status': false, 'message': 'Token tidak ditemukan'};

      final response = await http.post(
        Uri.parse('$baseUrl/admin/program-donasi'),
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

      if (token == null) return {'status': false, 'message': 'Token tidak ditemukan'};

      final response = await http.put(
        Uri.parse('$baseUrl/admin/program-donasi/$id'),
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

      if (token == null) return {'status': false, 'message': 'Token tidak ditemukan'};

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/program-donasi/$id'),
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

  static Future<Map<String, dynamic>> getProgramDonasiDetail(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return {'status': false, 'message': 'Token tidak ditemukan'};

      final response = await http.get(
        Uri.parse('$baseUrl/admin/program-donasi/$id'),
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
  // 💳 PAYMENT SYSTEM
  // ========================
  static Future<Map<String, dynamic>> createPayment({
    required double amount,
    required String name,
    required String email,
    required String phone,
    required double emisi,
    String? vehicleType,
    double? jarak,
    String? kapasitas,
    String? bahanBakar,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final uri = Uri.parse('$baseUrl/create-payment');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final Map<String, dynamic> bodyMap = {
        "amount": amount.toInt(),
        "emisi": emisi,
        "name": name,
        "email": email,
        "phone": phone,
      };

      if (vehicleType != null) bodyMap['vehicle_type'] = vehicleType;
      if (jarak != null) bodyMap['jarak'] = jarak;
      if (kapasitas != null) bodyMap['kapasitas'] = kapasitas;
      if (bahanBakar != null) bodyMap['bahan_bakar'] = bahanBakar;

      final body = jsonEncode(bodyMap);

      final response = await http.post(uri, headers: headers, body: body);

      final data = jsonDecode(response.body);

      String? redirect =
          data['redirect_url'] ?? data['snap_url'] ?? data['payment_url'];

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'redirect_url': redirect,
        'order_id': data['order_id'] ?? data['data']?['order_id'],
        'message': data['message'] ?? 'Payment created successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
        'redirect_url': null,
      };
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final uri = Uri.parse('$baseUrl/check-status/$orderId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  // ========================
  // 🧮 computeAmount
  // ========================
  static double computeAmount(double emisiKg, double hargaPerKg) {
    final raw = emisiKg * hargaPerKg;
    if (raw < 1) return 1;
    return double.parse(raw.toStringAsFixed(0));
  }

  // ========================
  // 🌿 EMISI FEATURE
  // ========================
  static Future<Map<String, dynamic>> saveEmisi({
    required String userId,
    required double emisiKg,
    required double jarakKm,
    required int durasiMenit,
    required String jenisKendaraan,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final uri = Uri.parse('$baseUrl/emisi/store');

      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'user_id': userId,
        'emisi_kg': emisiKg,
        'jarak_km': jarakKm,
        'durasi_menit': durasiMenit,
        'jenis_kendaraan': jenisKendaraan,
      });

      final response = await http.post(uri, headers: headers, body: body);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTotalEmisiBulanIni({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final uri = Uri.parse('$baseUrl/emisi/total-bulan-ini')
          .replace(queryParameters: {'user_id': userId});

      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateStatusBayar({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final uri = Uri.parse('$baseUrl/emisi/update-status-bayar');

      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({'user_id': userId});

      final response = await http.post(uri, headers: headers, body: body);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}