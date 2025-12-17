import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';
import 'login_page.dart';

class EditProfilPage extends StatefulWidget {
  final String nama;
  final String email;
  final String noHp;
  final String? fotoProfil;

  const EditProfilPage({
    super.key,
    required this.nama,
    required this.email,
    required this.noHp,
    this.fotoProfil,
  });

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  late TextEditingController namaController;
  late TextEditingController emailController;
  late TextEditingController noHpController;
  late TextEditingController passwordLamaController;
  late TextEditingController passwordBaruController;
  late TextEditingController confirmPasswordController;

  bool _isPasswordLamaVisible = false;
  bool _isPasswordBaruVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _showChangePassword = false;

  File? _imageFile;
  String? _networkImageUrl;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.nama);
    emailController = TextEditingController(text: widget.email);
    noHpController = TextEditingController(text: widget.noHp);
    passwordLamaController = TextEditingController();
    passwordBaruController = TextEditingController();
    confirmPasswordController = TextEditingController();
    _networkImageUrl = widget.fotoProfil;
    
    print('🔍 Init Edit Profil - Foto URL: $_networkImageUrl');
  }

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    noHpController.dispose();
    passwordLamaController.dispose();
    passwordBaruController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ Pick image dari galeri dengan error handling
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _networkImageUrl = null; // Clear network image
        });
        print('✅ Foto dipilih: ${pickedFile.path}');
        _showSnackBar('Foto berhasil dipilih. Klik "Simpan Perubahan" untuk mengupload', Colors.green);
      }
    } catch (e) {
      print('❌ Error pick image: $e');
      _showSnackBar('Gagal memilih foto: $e', Colors.red);
    }
  }

  // ✅ Validasi password (SAMA DENGAN REGISTER - 8 karakter, huruf besar, kecil, angka, spesial)
  String? _validatePassword(String password) {
    if (password.isEmpty) return null;
    if (password.length < 8) return 'Minimal 8 karakter';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Harus ada huruf besar';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Harus ada huruf kecil';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Harus ada angka';
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Harus ada karakter spesial';
    }
    return null;
  }

  // ✅ Simpan perubahan profil
  Future<void> _saveProfile() async {
    // Validasi input
    if (namaController.text.trim().isEmpty) {
      _showSnackBar('Nama tidak boleh kosong', Colors.red);
      return;
    }

    if (emailController.text.trim().isEmpty) {
      _showSnackBar('Email tidak boleh kosong', Colors.red);
      return;
    }

    // Validasi email format
    if (!emailController.text.contains('@')) {
      _showSnackBar('Format email tidak valid', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('📤 Mengirim update profil...');
    print('📝 Nama: ${namaController.text}');
    print('📧 Email: ${emailController.text}');
    print('📱 No HP: ${noHpController.text}');
    if (_imageFile != null) {
      print('📸 Dengan foto baru: ${_imageFile!.path}');
    }

    final result = await ApiService.updateProfil(
      nama: namaController.text.trim(),
      email: emailController.text.trim(),
      nomorHp: noHpController.text.trim(),
      fotoProfil: _imageFile,
    );

    print('📥 Response update profil: $result');

    setState(() {
      _isLoading = false;
    });

    if (result['status'] == true) {
      _showSnackBar('Profil berhasil diperbarui! 🎉', Colors.green);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true); // Return true untuk refresh profil page
      }
    } else {
      // Handle error response
      String errorMessage = 'Gagal memperbarui profil';
      
      if (result['errors'] != null) {
        final errors = result['errors'] as Map<String, dynamic>;
        final firstError = errors.values.first;
        errorMessage = firstError is List ? firstError.first : firstError.toString();
      } else if (result['message'] != null) {
        errorMessage = result['message'];
      }
      
      _showSnackBar(errorMessage, Colors.red);
    }
  }

  // ✅ Ganti password
  Future<void> _changePassword() async {
    // Validasi password lama
    if (passwordLamaController.text.isEmpty) {
      _showSnackBar('Password lama tidak boleh kosong', Colors.red);
      return;
    }

    // Validasi password baru
    if (passwordBaruController.text.isEmpty) {
      _showSnackBar('Password baru tidak boleh kosong', Colors.red);
      return;
    }

    final passwordError = _validatePassword(passwordBaruController.text);
    if (passwordError != null) {
      _showSnackBar(passwordError, Colors.red);
      return;
    }

    // Validasi konfirmasi password
    if (confirmPasswordController.text.isEmpty) {
      _showSnackBar('Konfirmasi password tidak boleh kosong', Colors.red);
      return;
    }

    if (passwordBaruController.text != confirmPasswordController.text) {
      _showSnackBar('Konfirmasi password tidak cocok', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('🔐 Mengirim request ganti password...');

    final result = await ApiService.changePassword(
      passwordLama: passwordLamaController.text,
      passwordBaru: passwordBaruController.text,
      konfirmasiPassword: confirmPasswordController.text,
    );

    print('📥 Response change password: $result');

    setState(() {
      _isLoading = false;
    });

    if (result['status'] == true) {
      // Password berhasil diubah, logout otomatis
      _showSnackBar('Password berhasil diubah! Silakan login kembali', Colors.green);
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } else {
      _showSnackBar(result['message'] ?? 'Gagal mengubah password', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Edit Profil"),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ===== FOTO PROFIL =====
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty
                            ? NetworkImage(_networkImageUrl!)
                            : null) as ImageProvider?,
                    onBackgroundImageError: _networkImageUrl != null
                        ? (exception, stackTrace) {
                            print('❌ Error loading network image: $exception');
                          }
                        : null,
                    child: (_imageFile == null && (_networkImageUrl == null || _networkImageUrl!.isEmpty))
                        ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            TextButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.image, size: 18),
              label: const Text(
                "Ganti Foto Profil",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
              ),
            ),

            const SizedBox(height: 25),

            // ===== FORM PROFIL =====
            _inputField("Nama Lengkap", namaController, Icons.person),
            const SizedBox(height: 15),
            _inputField("Email", emailController, Icons.email),
            const SizedBox(height: 15),
            _inputField("Nomor HP", noHpController, Icons.phone),

            const SizedBox(height: 30),

            // ===== TOMBOL SIMPAN PROFIL =====
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Simpan Perubahan",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 1.5),
            const SizedBox(height: 20),

            // ===== TOGGLE GANTI PASSWORD =====
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListTile(
                leading: const Icon(Icons.lock_reset, color: Color(0xFF4CAF50)),
                title: const Text(
                  'Ganti Password',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                trailing: Icon(
                  _showChangePassword ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade600,
                ),
                onTap: () {
                  setState(() {
                    _showChangePassword = !_showChangePassword;
                  });
                },
              ),
            ),

            // ===== FORM GANTI PASSWORD =====
            if (_showChangePassword) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubah Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Password harus minimal 8 karakter dengan huruf besar, huruf kecil, angka, dan karakter spesial',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Lama
                    _passwordField(
                      "Password Lama",
                      passwordLamaController,
                      _isPasswordLamaVisible,
                      () {
                        setState(() {
                          _isPasswordLamaVisible = !_isPasswordLamaVisible;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // Password Baru
                    _passwordField(
                      "Password Baru",
                      passwordBaruController,
                      _isPasswordBaruVisible,
                      () {
                        setState(() {
                          _isPasswordBaruVisible = !_isPasswordBaruVisible;
                        });
                      },
                    ),

                    // Password strength indicator
                    if (passwordBaruController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _validatePassword(passwordBaruController.text) != null
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _validatePassword(passwordBaruController.text) != null
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              size: 16,
                              color: _validatePassword(passwordBaruController.text) != null
                                  ? Colors.redAccent
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _validatePassword(passwordBaruController.text) ??
                                    '✓ Password kuat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _validatePassword(passwordBaruController.text) != null
                                      ? Colors.redAccent
                                      : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 15),

                    // Konfirmasi Password
                    _passwordField(
                      "Konfirmasi Password Baru",
                      confirmPasswordController,
                      _isConfirmPasswordVisible,
                      () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Tombol Ubah Password
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : _changePassword,
                        icon: const Icon(Icons.lock_reset),
                        label: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Ubah Password',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    
                    // Warning
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Setelah mengubah password, Anda akan logout otomatis dan harus login kembali.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== WIDGET INPUT FIELD =====
  Widget _inputField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      enabled: !_isLoading,
      keyboardType: icon == Icons.email 
          ? TextInputType.emailAddress 
          : (icon == Icons.phone ? TextInputType.phone : TextInputType.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  // ===== WIDGET PASSWORD FIELD =====
  Widget _passwordField(
    String label,
    TextEditingController controller,
    bool isVisible,
    VoidCallback toggleVisibility,
  ) {
    return TextField(
      controller: controller,
      enabled: !_isLoading,
      obscureText: !isVisible,
      onChanged: (value) {
        if (label.contains("Baru")) {
          setState(() {}); // Update password strength indicator
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF4CAF50)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: toggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}