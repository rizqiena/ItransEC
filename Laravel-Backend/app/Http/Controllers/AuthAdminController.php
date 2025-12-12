<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Admin;
use Illuminate\Support\Facades\Hash;

class AuthAdminController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'Email_Admin' => 'required|email',
            'Password_Admin' => 'required'
        ]);

        $admin = Admin::where('Email_Admin', $request->Email_Admin)->first();

        if (!$admin || !Hash::check($request->Password_Admin, $admin->Password_Admin)) {
            return response()->json([
                'status' => false,
                'message' => 'Email atau password salah'
            ], 401);
        }

        $token = $admin->createToken('admin_token')->plainTextToken;

        return response()->json([
            'status' => true,
            'message' => 'Login admin berhasil',
            'token' => $token,
            'data' => $admin
        ]);
    }
}
