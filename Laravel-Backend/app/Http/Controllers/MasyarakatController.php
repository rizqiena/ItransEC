<?php

namespace App\Http\Controllers;

use App\Models\Masyarakat;
use App\Models\Admin;
use Illuminate\Http\Request;

class MasyarakatController extends Controller
{
    /**
     * Tampilkan semua data masyarakat (khusus admin)
     * Support: pagination, search
     */
    public function index(Request $request)
    {
        // ✅ VALIDASI: Hanya admin yang bisa akses
        $user = $request->user();
        
        if (!($user instanceof Admin)) {
            return response()->json([
                'status' => false,
                'message' => 'Unauthorized. Hanya admin yang dapat mengakses data ini.'
            ], 403);
        }

        // ✅ AMBIL PARAMETER
        $search = $request->input('search', '');
        $perPage = $request->input('per_page', 50); // Default 50 data per halaman
        
        // ✅ QUERY
        $query = Masyarakat::select('Id_Masyarakat', 'Nama_Masyarakat', 'Email_Masyarakat', 'created_at');
        
        // ✅ SEARCH (jika ada parameter search)
        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('Nama_Masyarakat', 'like', "%{$search}%")
                  ->orWhere('Email_Masyarakat', 'like', "%{$search}%");
            });
        }
        
        // ✅ PAGINATION
        $masyarakat = $query->orderBy('created_at', 'desc')->paginate($perPage);

        return response()->json([
            'status' => true,
            'data' => $masyarakat->items(),
            'total' => $masyarakat->total(),
            'current_page' => $masyarakat->currentPage(),
            'last_page' => $masyarakat->lastPage(),
            'per_page' => $masyarakat->perPage(),
        ]);
    }

    /**
     * Dashboard statistics (untuk card di dashboard admin)
     */
    public function stats(Request $request)
    {
        // ✅ VALIDASI: Hanya admin yang bisa akses
        $user = $request->user();
        
        if (!($user instanceof Admin)) {
            return response()->json([
                'status' => false,
                'message' => 'Unauthorized.'
            ], 403);
        }

        return response()->json([
            'status' => true,
            'data' => [
                'total_user' => Masyarakat::count(),
                // Nanti tambahkan query untuk berita & penerima kalau tabelnya sudah ada
                // 'total_berita' => Berita::count(),
                // 'total_penerima' => Penerima::count(),
            ]
        ]);
    }

    /**
     * Detail satu masyarakat by ID (opsional, untuk detail page)
     */
    public function show(Request $request, $id)
    {
        // ✅ VALIDASI: Hanya admin yang bisa akses
        $user = $request->user();
        
        if (!($user instanceof Admin)) {
            return response()->json([
                'status' => false,
                'message' => 'Unauthorized.'
            ], 403);
        }

        $masyarakat = Masyarakat::find($id);

        if (!$masyarakat) {
            return response()->json([
                'status' => false,
                'message' => 'User tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'status' => true,
            'data' => $masyarakat
        ]);
    }

    /**
     * Delete masyarakat by ID (opsional, kalau butuh fitur hapus user)
     */
    public function destroy(Request $request, $id)
    {
        // ✅ VALIDASI: Hanya admin yang bisa akses
        $user = $request->user();
        
        if (!($user instanceof Admin)) {
            return response()->json([
                'status' => false,
                'message' => 'Unauthorized.'
            ], 403);
        }

        $masyarakat = Masyarakat::find($id);

        if (!$masyarakat) {
            return response()->json([
                'status' => false,
                'message' => 'User tidak ditemukan'
            ], 404);
        }

        $masyarakat->delete();

        return response()->json([
            'status' => true,
            'message' => 'User berhasil dihapus'
        ]);
    }
}