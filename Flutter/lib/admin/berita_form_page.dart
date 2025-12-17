import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/berita_services.dart';
import '../models/berita_model.dart';

class BeritaFormPage extends StatefulWidget {
  final Berita? berita; // Null = tambah, ada value = edit

  const BeritaFormPage({super.key, this.berita});

  @override
  State<BeritaFormPage> createState() => _BeritaFormPageState();
}

class _BeritaFormPageState extends State<BeritaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();

  File? _imageFile;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  DateTime? _selectedDate;

  bool get isEditMode => widget.berita != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadBeritaData();
    } else {
      // Set default date to today
      _selectedDate = DateTime.now();
      _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }
  }

  void _loadBeritaData() {
    final berita = widget.berita!;
    _judulController.text = berita.judulBerita;
    _deskripsiController.text = berita.deskripsiBerita;
    _tanggalController.text = berita.tanggalBerita;
    _existingImageUrl = berita.gambarBerita;
    
    // Parse tanggal
    try {
      _selectedDate = DateTime.parse(berita.tanggalBerita);
    } catch (e) {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  // 📅 Pilih Tanggal
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // 🖼️ Pilih Gambar
  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: $e', isError: true);
    }
  }

  // 📷 Ambil Foto dari Kamera
  Future<void> _takePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil foto: $e', isError: true);
    }
  }

  // 📸 Dialog Pilih Sumber Gambar
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🗑️ Hapus Gambar
  void _removeImage() {
    setState(() {
      _imageFile = null;
      _existingImageUrl = null;
    });
  }

  // 💾 Simpan Berita
  Future<void> _simpanBerita() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi gambar (opsional, bisa dihapus jika gambar tidak wajib)
    if (!isEditMode && _imageFile == null) {
      _showSnackBar('Silakan pilih gambar untuk berita', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (isEditMode) {
        // Update berita
        result = await BeritaService.updateBerita(
          id: widget.berita!.idBerita,
          judul: _judulController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          tanggal: _tanggalController.text,
          gambar: _imageFile,
        );
      } else {
        // Create berita baru
        result = await BeritaService.createBerita(
          judul: _judulController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          tanggal: _tanggalController.text,
          gambar: _imageFile,
        );
      }

      if (!mounted) return;

      if (result['status'] == true) {
        _showSnackBar(
          isEditMode ? 'Berita berhasil diperbarui' : 'Berita berhasil ditambahkan',
        );
        // Delay sebentar agar snackbar terlihat
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(context, true); // Return true untuk refresh
      } else {
        _showSnackBar(
          result['message'] ?? 'Gagal menyimpan berita',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Berita' : 'Tambah Berita'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF2F5FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ Preview Gambar
              _buildImageSection(),
              const SizedBox(height: 24),

              // 📝 Input Judul
              _buildInputLabel('Judul Berita', required: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _judulController,
                decoration: _buildInputDecoration(
                  hintText: 'Masukkan judul berita',
                  prefixIcon: Icons.title,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul berita harus diisi';
                  }
                  if (value.trim().length < 5) {
                    return 'Judul minimal 5 karakter';
                  }
                  if (value.trim().length > 255) {
                    return 'Judul maksimal 255 karakter';
                  }
                  return null;
                },
                maxLength: 255,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // 📝 Input Deskripsi
              _buildInputLabel('Deskripsi Berita', required: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 10,
                decoration: _buildInputDecoration(
                  hintText: 'Masukkan isi/deskripsi berita secara lengkap',
                  prefixIcon: Icons.description,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi berita harus diisi';
                  }
                  if (value.trim().length < 20) {
                    return 'Deskripsi minimal 20 karakter';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // 📅 Input Tanggal
              _buildInputLabel('Tanggal Berita', required: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tanggalController,
                readOnly: true,
                decoration: _buildInputDecoration(
                  hintText: 'Pilih tanggal',
                  prefixIcon: Icons.calendar_today,
                  suffixIcon: Icons.arrow_drop_down,
                ),
                onTap: _pickDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal berita harus dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // 💾 Tombol Simpan
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // === WIDGET BUILDERS ===

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Gambar Berita', required: !isEditMode),
        const SizedBox(height: 8),
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              if (_imageFile != null || _existingImageUrl != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _removeImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library, size: 20),
              label: const Text('Galeri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Kamera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _existingImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          'Tap untuk memilih gambar',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Maksimal 2MB',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF4CAF50)),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: alignLabelWithHint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _simpanBerita,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(
          _isLoading
              ? 'Menyimpan...'
              : isEditMode
                  ? 'Update Berita'
                  : 'Simpan Berita',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: const Color(0xFF4CAF50).withOpacity(0.5),
        ),
      ),
    );
  }
}