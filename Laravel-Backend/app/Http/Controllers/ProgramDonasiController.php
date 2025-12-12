<?php

namespace App\Http\Controllers;

use App\Models\ProgramDonasi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProgramDonasiController extends Controller
{
    /**
     * Display a listing of program donasi
     */
    public function index(Request $request)
    {
        try {
            $perPage = $request->input('per_page', 10);
            $search = $request->input('search', '');

            $query = ProgramDonasi::query();

            if (!empty($search)) {
                $query->where(function($q) use ($search) {
                    $q->where('Judul_Program', 'like', "%{$search}%")
                      ->orWhere('Nama_Perusahaan', 'like', "%{$search}%")
                      ->orWhere('Rekening_Donasi', 'like', "%{$search}%");
                });
            }

            $query->orderBy('created_at', 'desc');
            $programs = $query->paginate($perPage);

            return response()->json([
                'status' => true,
                'message' => 'Data program donasi berhasil diambil',
                'data' => $programs->items(),
                'pagination' => [
                    'current_page' => $programs->currentPage(),
                    'last_page' => $programs->lastPage(),
                    'per_page' => $programs->perPage(),
                    'total' => $programs->total(),
                    'from' => $programs->firstItem(),
                    'to' => $programs->lastItem(),
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil data program donasi',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a newly created program donasi
     */
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'Judul_Program' => 'required|string|max:255',
                'Nama_Perusahaan' => 'required|string|max:255',
                'Rekening_Donasi' => 'required|string|max:50',
                'Target_Donasi' => 'required|numeric|min:0',
                'Tanggal_Mulai_Donasi' => 'required|date',
                'Tanggal_Selesai_Donasi' => 'required|date|after_or_equal:Tanggal_Mulai_Donasi',
                'Emisi_Donasi' => 'nullable|numeric|min:0',
            ], [
                'Judul_Program.required' => 'Judul program harus diisi',
                'Nama_Perusahaan.required' => 'Nama perusahaan harus diisi',
                'Rekening_Donasi.required' => 'Nomor rekening harus diisi',
                'Target_Donasi.required' => 'Target donasi harus diisi',
                'Target_Donasi.numeric' => 'Target donasi harus berupa angka',
                'Tanggal_Mulai_Donasi.required' => 'Tanggal mulai harus diisi',
                'Tanggal_Selesai_Donasi.required' => 'Tanggal selesai harus diisi',
                'Tanggal_Selesai_Donasi.after_or_equal' => 'Tanggal selesai harus setelah atau sama dengan tanggal mulai',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => false,
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors()
                ], 422);
            }

            $program = ProgramDonasi::create([
                'Judul_Program' => $request->Judul_Program,
                'Nama_Perusahaan' => $request->Nama_Perusahaan,
                'Rekening_Donasi' => $request->Rekening_Donasi,
                'Target_Donasi' => $request->Target_Donasi,
                'Tanggal_Mulai_Donasi' => $request->Tanggal_Mulai_Donasi,
                'Tanggal_Selesai_Donasi' => $request->Tanggal_Selesai_Donasi,
                'Emisi_Donasi' => $request->Emisi_Donasi ?? 0,
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Program donasi berhasil ditambahkan',
                'data' => $program
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal menambahkan program donasi',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified program donasi
     */
    public function show($id)
    {
        try {
            $program = ProgramDonasi::find($id);

            if (!$program) {
                return response()->json([
                    'status' => false,
                    'message' => 'Program donasi tidak ditemukan'
                ], 404);
            }

            return response()->json([
                'status' => true,
                'message' => 'Data program donasi berhasil diambil',
                'data' => $program
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil data program donasi',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update the specified program donasi
     */
    public function update(Request $request, $id)
    {
        try {
            $program = ProgramDonasi::find($id);

            if (!$program) {
                return response()->json([
                    'status' => false,
                    'message' => 'Program donasi tidak ditemukan'
                ], 404);
            }

            $validator = Validator::make($request->all(), [
                'Judul_Program' => 'sometimes|required|string|max:255',
                'Nama_Perusahaan' => 'sometimes|required|string|max:255',
                'Rekening_Donasi' => 'sometimes|required|string|max:50',
                'Target_Donasi' => 'sometimes|required|numeric|min:0',
                'Tanggal_Mulai_Donasi' => 'sometimes|required|date',
                'Tanggal_Selesai_Donasi' => 'sometimes|required|date|after_or_equal:Tanggal_Mulai_Donasi',
                'Emisi_Donasi' => 'nullable|numeric|min:0',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => false,
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors()
                ], 422);
            }

            $program->update($request->all());

            return response()->json([
                'status' => true,
                'message' => 'Program donasi berhasil diperbarui',
                'data' => $program
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal memperbarui program donasi',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified program donasi
     */
    public function destroy($id)
    {
        try {
            $program = ProgramDonasi::find($id);

            if (!$program) {
                return response()->json([
                    'status' => false,
                    'message' => 'Program donasi tidak ditemukan'
                ], 404);
            }

            $program->delete();

            return response()->json([
                'status' => true,
                'message' => 'Program donasi berhasil dihapus'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal menghapus program donasi',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get total count of program donasi
     */
    public function getProgramDonasiCount()
    {
        try {
            $total = ProgramDonasi::count();
            $active = ProgramDonasi::active()->count();

            return response()->json([
                'status' => true,
                'data' => [
                    'total' => $total,
                    'active' => $active,
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil jumlah program donasi',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}