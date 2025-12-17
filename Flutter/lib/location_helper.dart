import 'package:geolocator/geolocator.dart';

class LocationHelper {
  /// Cek & minta izin lokasi.
  /// return true kalau diizinkan, false kalau ditolak / tidak tersedia.
  static Future<bool> ensureLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan lokasi (GPS) aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Di sini kamu bisa nanti tambahin snackbar / dialog kalau mau
      return false;
    }

    // 2. Cek status permission saat ini
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // 3. Kalau denied, kita minta izin
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // User tetap nolak
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // User pilih "Don't ask again"
      // Perlu diarahkan ke Settings, tapi untuk sekarang kita anggap false dulu
      return false;
    }

    // Sampai sini berarti permission diizinkan (while in use / always)
    return true;
  }
}
