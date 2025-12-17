<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rules\Password;

class ProfilMasyarakatController extends Controller
{
    /**
     * Tampilkan profil user yang sedang login
     */
    public function show(Request $request)
    {
        $user = $request->user();
        
        // ✅ PERBAIKAN: Manual build response dengan foto URL yang benar
        return response()->json([
            'status' => true,
            'data' => [
                'Id_Masyarakat' => $user->Id_Masyarakat,
                'Nama_Masyarakat' => $user->Nama_Masyarakat,
                'Email_Masyarakat' => $user->Email_Masyarakat,
                'Nomor_HP' => $user->Nomor_HP,
                'Profil_Masyarakat' => $user->Profil_Masyarakat, // Accessor otomatis jalan
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ]);
    }

    /**
     * Update profil user (dengan upload foto)
     */
    public function update(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'Nama_Masyarakat' => 'required|string|max:255',
            'Email_Masyarakat' => [
                'required',
                'email',
                'unique:masyarakats,Email_Masyarakat,' . $user->Id_Masyarakat . ',Id_Masyarakat'
            ],
            'Nomor_HP' => 'nullable|string|max:20',
            'foto_profil' => 'nullable|image|mimes:jpeg,png,jpg|max:2048', // Max 2MB
        ], [
            'Nama_Masyarakat.required' => 'Nama tidak boleh kosong',
            'Email_Masyarakat.required' => 'Email tidak boleh kosong',
            'Email_Masyarakat.email' => 'Format email tidak valid',
            'Email_Masyarakat.unique' => 'Email sudah digunakan',
            'foto_profil.image' => 'File harus berupa gambar',
            'foto_profil.mimes' => 'Format gambar harus jpeg, png, atau jpg',
            'foto_profil.max' => 'Ukuran gambar maksimal 2MB',
        ]);

        $data = [
            'Nama_Masyarakat' => $request->Nama_Masyarakat,
            'Email_Masyarakat' => $request->Email_Masyarakat,
            'Nomor_HP' => $request->Nomor_HP,
        ];

        // ✅ Handle upload foto profil
        if ($request->hasFile('foto_profil')) {
            // Hapus foto lama jika ada
            if ($user->getRawOriginal('Profil_Masyarakat')) {
                $oldPath = $user->getRawOriginal('Profil_Masyarakat');
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);
                }
            }

            // Upload foto baru
            $file = $request->file('foto_profil');
            $filename = 'profil_' . $user->Id_Masyarakat . '_' . time() . '.' . $file->getClientOriginalExtension();
            $path = $file->storeAs('profil', $filename, 'public');
            $data['Profil_Masyarakat'] = $path;
        }

        $user->update($data);

        // ✅ PERBAIKAN: Return dengan data lengkap
        return response()->json([
            'status' => true,
            'message' => 'Profil berhasil diperbarui',
            'data' => [
                'Id_Masyarakat' => $user->Id_Masyarakat,
                'Nama_Masyarakat' => $user->Nama_Masyarakat,
                'Email_Masyarakat' => $user->Email_Masyarakat,
                'Nomor_HP' => $user->Nomor_HP,
                'Profil_Masyarakat' => $user->Profil_Masyarakat, // URL full
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ]);
    }

    /**
     * Ganti password (VALIDASI SAMA DENGAN REGISTRASI)
     */
    public function changePassword(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'password_lama' => 'required',
            'password_baru' => [
                'required',
                'different:password_lama',
                // ✅ VALIDASI SAMA DENGAN REGISTRASI:
                Password::min(8)           // Minimal 8 karakter
                    ->letters()            // Harus ada huruf
                    ->mixedCase()          // Huruf besar DAN kecil
                    ->numbers()            // Harus ada angka
                    ->symbols()            // Harus ada karakter spesial
            ],
            'konfirmasi_password' => 'required|same:password_baru',
        ], [
            'password_lama.required' => 'Password lama tidak boleh kosong',
            'password_baru.required' => 'Password baru tidak boleh kosong',
            'password_baru.different' => 'Password baru harus berbeda dengan password lama',
            'konfirmasi_password.required' => 'Konfirmasi password tidak boleh kosong',
            'konfirmasi_password.same' => 'Konfirmasi password tidak cocok',
        ]);

        // Cek password lama
        if (!Hash::check($request->password_lama, $user->KataSandi_Masyarakat)) {
            return response()->json([
                'status' => false,
                'message' => 'Password lama salah'
            ], 401);
        }

        // Update password
        $user->update([
            'KataSandi_Masyarakat' => Hash::make($request->password_baru)
        ]);

        // Hapus semua token (logout dari semua device)
        $user->tokens()->delete();

        return response()->json([
            'status' => true,
            'message' => 'Password berhasil diubah. Silakan login kembali'
        ]);
    }
}