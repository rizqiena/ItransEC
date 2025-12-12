import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class EditPenerimaPage extends StatefulWidget {
  final Map<String, dynamic> programData;

  const EditPenerimaPage({super.key, required this.programData});

  @override
  State<EditPenerimaPage> createState() => _EditPenerimaPageState();
}

class _EditPenerimaPageState extends State<EditPenerimaPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController judulController;
  late TextEditingController perusahaanController;
  late TextEditingController rekeningController;
  late TextEditingController targetController;
  late TextEditingController terkumpulController;
  
  DateTime? tanggalMulai;
  DateTime? tanggalSelesai;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    judulController = TextEditingController(text: widget.programData['Judul_Program']);
    perusahaanController = TextEditingController(text: widget.programData['Nama_Perusahaan']);
    rekeningController = TextEditingController(text: widget.programData['Rekening_Donasi']);
    
    final target = double.tryParse(widget.programData['Target_Donasi'].toString()) ?? 0;
    targetController = TextEditingController(
      text: NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(target),
    );
    
    final terkumpul = double.tryParse(widget.programData['Emisi_Donasi'].toString()) ?? 0;
    terkumpulController = TextEditingController(
      text: NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(terkumpul),
    );

    try {
      tanggalMulai = DateTime.parse(widget.programData['Tanggal_Mulai_Donasi']);
      tanggalSelesai = DateTime.parse(widget.programData['Tanggal_Selesai_Donasi']);
    } catch (e) {
      tanggalMulai = DateTime.now();
      tanggalSelesai = DateTime.now().add(const Duration(days: 30));
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? tanggalMulai! : tanggalSelesai!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          tanggalMulai = picked;
        } else {
          tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _updateData() async {
    if (!_formKey.currentState!.validate()) return;

    if (tanggalMulai == null || tanggalSelesai == null) {
      _showSnackBar('Tanggal harus dipilih', Colors.red);
      return;
    }
    if (tanggalSelesai!.isBefore(tanggalMulai!)) {
      _showSnackBar('Tanggal selesai tidak boleh sebelum tanggal mulai', Colors.red);
      return;
    }

    setState(() => isLoading = true);

    final response = await ApiService.updateProgramDonasi(
      id: widget.programData['Id_Donasi'],
      judulProgram: judulController.text.trim(),
      namaPerusahaan: perusahaanController.text.trim(),
      rekeningDonasi: rekeningController.text.trim(),
      targetDonasi: double.parse(targetController.text.replaceAll(RegExp(r'[^0-9]'), '')),
      tanggalMulai: DateFormat('yyyy-MM-dd').format(tanggalMulai!),
      tanggalSelesai: DateFormat('yyyy-MM-dd').format(tanggalSelesai!),
      emisiDonasi: double.parse(terkumpulController.text.replaceAll(RegExp(r'[^0-9]'), '')),
    );

    setState(() => isLoading = false);

    if (mounted) {
      if (response['status'] == true) {
        _showSnackBar('Program donasi berhasil diperbarui', Colors.green);
        Navigator.pop(context, true);
      } else {
        _showSnackBar(
          response['message'] ?? 'Gagal memperbarui program',
          Colors.red,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          'Edit Program Donasi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionCard(
              title: 'Informasi Program',
              icon: Icons.info_outline,
              children: [
                _buildTextField(
                  controller: judulController,
                  label: 'Judul Program',
                  hint: 'Contoh: Bagi-bagi Sembako',
                  icon: Icons.title,
                  validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: perusahaanController,
                  label: 'Nama Perusahaan/Organisasi',
                  hint: 'Contoh: PT. Peduli Rakyat',
                  icon: Icons.business,
                  validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Informasi Keuangan',
              icon: Icons.account_balance_wallet,
              children: [
                _buildCurrencyField(
                  controller: targetController,
                  label: 'Target Donasi',
                  hint: '0',
                  icon: Icons.flag,
                  validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                ),
                const SizedBox(height: 16),
                _buildCurrencyField(
                  controller: terkumpulController,
                  label: 'Dana Terkumpul',
                  hint: '0',
                  icon: Icons.savings,
                  validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: rekeningController,
                  label: 'Nomor Rekening',
                  hint: 'Contoh: 1234567890',
                  icon: Icons.account_balance,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Periode Program',
              icon: Icons.calendar_month,
              children: [
                _buildDateField(
                  label: 'Tanggal Mulai',
                  date: tanggalMulai,
                  onTap: () => _selectDate(context, true),
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  label: 'Tanggal Selesai',
                  date: tanggalSelesai,
                  onTap: () => _selectDate(context, false),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: isLoading ? null : _updateData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 8),
                        Text(
                          'Update Program',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.isEmpty) return newValue;
          final number = int.parse(newValue.text);
          final formatted = NumberFormat.currency(
            locale: 'id',
            symbol: '',
            decimalDigits: 0,
          ).format(number);
          return TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }),
      ],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: 'Rp ',
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date == null
                        ? 'Pilih tanggal'
                        : DateFormat('dd MMMM yyyy').format(date), // ← FIXED: Hapus 'id_ID'
                    style: TextStyle(
                      fontSize: 15,
                      color: date == null ? Colors.grey[400] : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    judulController.dispose();
    perusahaanController.dispose();
    rekeningController.dispose();
    targetController.dispose();
    terkumpulController.dispose();
    super.dispose();
  }
}