<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Masyarakat;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AuthMasyarakatController extends Controller
{
    // REGISTER
    public function register(Request $request)
    {
        $request->validate([
            'Nama_Masyarakat' => 'required|string|max:255',
            'Email_Masyarakat' => [
                'required',
                'email:rfc,dns', // ✅ Validasi email lebih ketat
                'unique:masyarakats,Email_Masyarakat'
            ],
            'KataSandi_Masyarakat' => [
                'required',
                Password::min(8) // Minimal 8 karakter
                    ->letters() // Harus ada huruf
                    ->mixedCase() // Harus ada huruf besar DAN kecil
                    ->numbers() // Harus ada angka
                    ->symbols() // Harus ada karakter spesial (@$!%*#?&)
            ],
            'KataSandi_Masyarakat_Confirmation' => 'required|same:KataSandi_Masyarakat' // ✅ Validasi konfirmasi password
        ], [
            // Custom error messages
            'Nama_Masyarakat.required' => 'Nama tidak boleh kosong',
            'Email_Masyarakat.required' => 'Email tidak boleh kosong',
            'Email_Masyarakat.email' => 'Format email tidak valid',
            'Email_Masyarakat.unique' => 'Email sudah terdaftar',
            'KataSandi_Masyarakat.required' => 'Kata sandi tidak boleh kosong',
            'KataSandi_Masyarakat.min' => 'Kata sandi minimal 8 karakter',
            'KataSandi_Masyarakat_Confirmation.required' => 'Konfirmasi kata sandi tidak boleh kosong',
            'KataSandi_Masyarakat_Confirmation.same' => 'Konfirmasi kata sandi tidak cocok',
        ]);

        $masyarakat = Masyarakat::create([
            'Nama_Masyarakat' => $request->Nama_Masyarakat,
            'Email_Masyarakat' => $request->Email_Masyarakat,
            'KataSandi_Masyarakat' => Hash::make($request->KataSandi_Masyarakat),
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Registrasi berhasil',
            'data' => $masyarakat
        ]);
    }

    // LOGIN
    public function login(Request $request)
    {
        $request->validate([
            'Email_Masyarakat' => 'required|email',
            'KataSandi_Masyarakat' => 'required'
        ]);

        $user = Masyarakat::where('Email_Masyarakat', $request->Email_Masyarakat)->first();

        if (!$user || !Hash::check($request->KataSandi_Masyarakat, $user->KataSandi_Masyarakat)) {
            return response()->json([
                'status' => false,
                'message' => 'Email atau kata sandi salah'
            ], 401);
        }

        // Sanctum token
        $token = $user->createToken('masyarakat_token')->plainTextToken;

        return response()->json([
            'status' => true,
            'message' => 'Login berhasil',
            'token' => $token,
            'data' => $user
        ]);
    }

    // LOGOUT
    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();

        return response()->json([
            'status' => true,
            'message' => 'Logout berhasil'
        ]);
    }
}