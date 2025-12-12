import 'package:shared_preferences/shared_preferences.dart';

class EmissionSettings {
  static const _keyMonthlyLimit = 'monthly_limit_kg';

  static Future<double> getMonthlyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMonthlyLimit) ?? 50.0;
  }

  static Future<void> setMonthlyLimit(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMonthlyLimit, value);
  }
}
