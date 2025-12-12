<?php

namespace App\Http\Controllers;

use App\Models\Berita;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class BeritaController extends Controller
{
    // GET ALL BERITA (Untuk Admin & Masyarakat)
    public function index(Request $request)
    {
        try {
            $perPage = $request->get('per_page', 10);
            $search = $request->get('search', '');

            $query = Berita::with('admin:Id_Admin,Nama_Admin')
                ->orderBy('Tanggal_Berita', 'desc');

            if ($search) {
                $query->where('Judul_Berita', 'like', "%{$search}%")
                    ->orWhere('Deskripsi_Berita', 'like', "%{$search}%");
            }

            $beritas = $query->paginate($perPage);

            $beritas->getCollection()->transform(function ($berita) {
                return [
                    'Id_Berita' => $berita->Id_Berita,
                    'Judul_Berita' => $berita->Judul_Berita,
                    'Deskripsi_Berita' => $berita->Deskripsi_Berita,
                    'Gambar_Berita' => $berita->gambar_url,
                    'Tanggal_Berita' => $berita->Tanggal_Berita->format('Y-m-d'),
                    'Nama_Admin' => $berita->admin->Nama_Admin ?? 'Admin',
                    'Created_At' => $berita->created_at->format('Y-m-d H:i:s'),
                ];
            });

            return response()->json([
                'status' => true,
                'message' => 'Data berita berhasil diambil',
                'data' => $beritas->items(),
                'pagination' => [
                    'current_page' => $beritas->currentPage(),
                    'last_page' => $beritas->lastPage(),
                    'per_page' => $beritas->perPage(),
                    'total' => $beritas->total(),
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil data berita: ' . $e->getMessage()
            ], 500);
        }
    }

    // GET SINGLE BERITA
    public function show($id)
    {
        try {
            $berita = Berita::with('admin:Id_Admin,Nama_Admin')->find($id);

            if (!$berita) {
                return response()->json([
                    'status' => false,
                    'message' => 'Berita tidak ditemukan'
                ], 404);
            }

            return response()->json([
                'status' => true,
                'message' => 'Detail berita berhasil diambil',
                'data' => [
                    'Id_Berita' => $berita->Id_Berita,
                    'Judul_Berita' => $berita->Judul_Berita,
                    'Deskripsi_Berita' => $berita->Deskripsi_Berita,
                    'Gambar_Berita' => $berita->gambar_url,
                    'Tanggal_Berita' => $berita->Tanggal_Berita->format('Y-m-d'),
                    'Nama_Admin' => $berita->admin->Nama_Admin ?? 'Admin',
                    'Created_At' => $berita->created_at->format('Y-m-d H:i:s'),
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil detail berita: ' . $e->getMessage()
            ], 500);
        }
    }

    // CREATE BERITA (Admin Only)
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'Judul_Berita' => 'required|string|max:255',
            'Deskripsi_Berita' => 'required|string',
            'Gambar_Berita' => 'nullable|image|mimes:jpeg,jpg,png|max:2048',
            'Tanggal_Berita' => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $gambarPath = null;

            if ($request->hasFile('Gambar_Berita')) {
                $file = $request->file('Gambar_Berita');
                $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
                $file->storeAs('public/berita', $filename);
                $gambarPath = $filename;
            }

            $berita = Berita::create([
                'Id_Admin' => $request->user()->Id_Admin,
                'Judul_Berita' => $request->Judul_Berita,
                'Deskripsi_Berita' => $request->Deskripsi_Berita,
                'Gambar_Berita' => $gambarPath,
                'Tanggal_Berita' => $request->Tanggal_Berita,
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Berita berhasil ditambahkan',
                'data' => [
                    'Id_Berita' => $berita->Id_Berita,
                    'Judul_Berita' => $berita->Judul_Berita,
                    'Deskripsi_Berita' => $berita->Deskripsi_Berita,
                    'Gambar_Berita' => $berita->gambar_url,
                    'Tanggal_Berita' => $berita->Tanggal_Berita->format('Y-m-d'),
                ]
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal menambahkan berita: ' . $e->getMessage()
            ], 500);
        }
    }

    // UPDATE BERITA (Admin Only)
    public function update(Request $request, $id)
    {
        $berita = Berita::find($id);

        if (!$berita) {
            return response()->json([
                'status' => false,
                'message' => 'Berita tidak ditemukan'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'Judul_Berita' => 'required|string|max:255',
            'Deskripsi_Berita' => 'required|string',
            'Gambar_Berita' => 'nullable|image|mimes:jpeg,jpg,png|max:2048',
            'Tanggal_Berita' => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            if ($request->hasFile('Gambar_Berita')) {
                if ($berita->Gambar_Berita) {
                    Storage::delete('public/berita/' . $berita->Gambar_Berita);
                }

                $file = $request->file('Gambar_Berita');
                $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
                $file->storeAs('public/berita', $filename);
                $berita->Gambar_Berita = $filename;
            }

            $berita->update([
                'Judul_Berita' => $request->Judul_Berita,
                'Deskripsi_Berita' => $request->Deskripsi_Berita,
                'Tanggal_Berita' => $request->Tanggal_Berita,
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Berita berhasil diperbarui',
                'data' => [
                    'Id_Berita' => $berita->Id_Berita,
                    'Judul_Berita' => $berita->Judul_Berita,
                    'Deskripsi_Berita' => $berita->Deskripsi_Berita,
                    'Gambar_Berita' => $berita->gambar_url,
                    'Tanggal_Berita' => $berita->Tanggal_Berita->format('Y-m-d'),
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal memperbarui berita: ' . $e->getMessage()
            ], 500);
        }
    }

    // DELETE BERITA (Admin Only)
    public function destroy($id)
    {
        try {
            $berita = Berita::find($id);

            if (!$berita) {
                return response()->json([
                    'status' => false,
                    'message' => 'Berita tidak ditemukan'
                ], 404);
            }

            if ($berita->Gambar_Berita) {
                Storage::delete('public/berita/' . $berita->Gambar_Berita);
            }

            $berita->delete();

            return response()->json([
                'status' => true,
                'message' => 'Berita berhasil dihapus'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal menghapus berita: ' . $e->getMessage()
            ], 500);
        }
    }

    // GET BERITA COUNT (For Dashboard)
    public function getBeritaCount()
    {
        try {
            $total = Berita::count();
            
            return response()->json([
                'status' => true,
                'data' => [
                    'total_berita' => $total
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil jumlah berita: ' . $e->getMessage()
            ], 500);
        }
    }
}