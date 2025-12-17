import 'package:flutter/material.dart';
import '../services/emission_settings.dart';

class EmissionLimitSection extends StatefulWidget {
  const EmissionLimitSection({super.key});

  @override
  State<EmissionLimitSection> createState() => _EmissionLimitSectionState();
}

class _EmissionLimitSectionState extends State<EmissionLimitSection> {
  bool _loading = true;
  double _currentValue = 50.0;

  final double _minLimit = 5.0;
  final double _maxLimit = 500.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentLimit();
  }

  Future<void> _loadCurrentLimit() async {
    final limit = await EmissionSettings.getMonthlyLimit();

    setState(() {
      _currentValue = limit.clamp(_minLimit, _maxLimit);
      _loading = false;
    });
  }

  Future<void> _save() async {
    await EmissionSettings.setMonthlyLimit(_currentValue);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batas emisi bulanan tersimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFFF8FFF9), // sedikit hijau muda biar soft
      elevation: 8, // 🆙 lebih tinggi biar bayangan kelihatan
      shadowColor: Colors.black.withOpacity(0.15), // 🆙 shadow lebih tebal
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(
                    Icons.speed,
                    size: 18,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Batas Emisi Bulanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Atur target maksimum emisi CO₂ yang ingin kamu capai setiap bulan.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            // Angka besar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentValue.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Kg CO₂',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Slider minimalis
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: const Color(0xFF4CAF50),
                inactiveTrackColor: const Color(0xFFE5F2E9),
                thumbColor: const Color(0xFF4CAF50),
                overlayColor: const Color(0x334CAF50),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                min: _minLimit,
                max: _maxLimit,
                divisions: ((_maxLimit - _minLimit) ~/ 5).toInt(),
                value: _currentValue,
                onChanged: (value) {
                  setState(() {
                    _currentValue = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_minLimit.toStringAsFixed(0)}  •  ${_maxLimit.toStringAsFixed(0)} Kg',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text(
                    'Simpan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
