<?php

namespace App\Http\Controllers;

use App\Models\Donasi;
use App\Models\ProgramDonasi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DonasiController extends Controller
{
    /**
     * Get Donasi Statistics (For Admin Dashboard)
     * GET /api/admin/donasi/stats
     */
    public function getStats()
    {
        try {
            Log::info('📊 [DonasiController] getStats called');

            // Total donasi berhasil
            $totalDonasi = Donasi::where('payment_status', 'settlement')->sum('nominal_donasi');
            
            // Total emisi yang sudah ditebus
            $totalEmisi = Donasi::where('payment_status', 'settlement')->sum('emisi_kg');
            
            // Jumlah transaksi berhasil
            $totalTransaksi = Donasi::where('payment_status', 'settlement')->count();
            
            // Jumlah donatur unik
            $totalDonatur = Donasi::where('payment_status', 'settlement')
                ->distinct('user_email')
                ->count('user_email');
            
            // Donasi per status
            $donasiPerStatus = Donasi::select('payment_status', DB::raw('count(*) as total'))
                ->groupBy('payment_status')
                ->get()
                ->pluck('total', 'payment_status');
            
            // Donasi per program
            $donasiPerProgram = Donasi::select('program_name', DB::raw('count(*) as total'), DB::raw('sum(nominal_donasi) as total_nominal'))
                ->where('payment_status', 'settlement')
                ->groupBy('program_name')
                ->get();
            
            // Donasi bulan ini
            $donasiBulanIni = Donasi::where('payment_status', 'settlement')
                ->whereMonth('created_at', date('m'))
                ->whereYear('created_at', date('Y'))
                ->sum('nominal_donasi');

            Log::info('✅ [DonasiController] Stats retrieved successfully', [
                'total_donasi' => $totalDonasi,
                'total_transaksi' => $totalTransaksi,
            ]);
            
            return response()->json([
                'success' => true,
                'data' => [
                    'total_donasi' => (float) $totalDonasi,
                    'total_emisi' => (float) $totalEmisi,
                    'total_transaksi' => $totalTransaksi,
                    'total_donatur' => $totalDonatur,
                    'donasi_bulan_ini' => (float) $donasiBulanIni,
                    'donasi_per_status' => $donasiPerStatus,
                    'donasi_per_program' => $donasiPerProgram,
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('❌ [DonasiController] Error getStats', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil statistik donasi',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get Donasi List (For Admin)
     * GET /api/admin/donasi/list
     */
    public function getList(Request $request)
    {
        try {
            Log::info('📋 [DonasiController] getList called', [
                'params' => $request->all()
            ]);

            $query = Donasi::orderBy('created_at', 'desc');
            
            // Filter by program
            if ($request->has('program_id') && $request->program_id) {
                $query->where('program_id', $request->program_id);
            }
            
            // Filter by status
            if ($request->has('status') && $request->status) {
                $query->where('payment_status', $request->status);
            }
            
            // Filter by date range
            if ($request->has('start_date') && $request->start_date) {
                $query->whereDate('created_at', '>=', $request->start_date);
            }
            
            if ($request->has('end_date') && $request->end_date) {
                $query->whereDate('created_at', '<=', $request->end_date);
            }
            
            // Search by name, email, or transaction ID
            if ($request->has('search') && $request->search) {
                $search = $request->search;
                $query->where(function($q) use ($search) {
                    $q->where('user_name', 'like', "%{$search}%")
                      ->orWhere('user_email', 'like', "%{$search}%")
                      ->orWhere('transaction_id', 'like', "%{$search}%");
                });
            }
            
            // Pagination
            $perPage = $request->get('per_page', 20);
            $donasis = $query->paginate($perPage);

            Log::info('✅ [DonasiController] List retrieved', [
                'total' => $donasis->total(),
                'per_page' => $perPage,
            ]);
            
            return response()->json([
                'success' => true,
                'data' => $donasis
            ]);
        } catch (\Exception $e) {
            Log::error('❌ [DonasiController] Error getList', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil list donasi',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get Donasi Detail (For Admin)
     * GET /api/admin/donasi/detail/{id}
     */
    public function getDetail($id)
    {
        try {
            Log::info('🔍 [DonasiController] getDetail called', ['id' => $id]);

            $donasi = Donasi::findOrFail($id);

            Log::info('✅ [DonasiController] Detail retrieved', [
                'transaction_id' => $donasi->transaction_id,
            ]);
            
            return response()->json([
                'success' => true,
                'data' => $donasi
            ]);
        } catch (\Exception $e) {
            Log::error('❌ [DonasiController] Error getDetail', [
                'id' => $id,
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Donasi tidak ditemukan',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    /**
     * Export Donasi (CSV/Excel)
     * GET /api/admin/donasi/export
     */
    public function export(Request $request)
    {
        try {
            Log::info('📤 [DonasiController] export called');

            $query = Donasi::orderBy('created_at', 'desc');
            
            // Apply same filters as getList
            if ($request->has('program_id') && $request->program_id) {
                $query->where('program_id', $request->program_id);
            }
            
            if ($request->has('status') && $request->status) {
                $query->where('payment_status', $request->status);
            }
            
            if ($request->has('start_date') && $request->start_date) {
                $query->whereDate('created_at', '>=', $request->start_date);
            }
            
            if ($request->has('end_date') && $request->end_date) {
                $query->whereDate('created_at', '<=', $request->end_date);
            }
            
            $donasis = $query->get();
            
            // Format data untuk export
            $exportData = $donasis->map(function($donasi) {
                return [
                    'Transaction ID' => $donasi->transaction_id,
                    'Tanggal' => $donasi->created_at->format('d-m-Y H:i'),
                    'Nama' => $donasi->user_name,
                    'Email' => $donasi->user_email,
                    'Phone' => $donasi->user_phone,
                    'Program' => $donasi->program_name,
                    'Emisi (kg)' => $donasi->emisi_kg,
                    'Nominal' => $donasi->nominal_donasi,
                    'Payment Method' => $donasi->payment_method ?? '-',
                    'Status' => $donasi->payment_status,
                ];
            });

            Log::info('✅ [DonasiController] Export completed', [
                'total_records' => $exportData->count(),
            ]);
            
            return response()->json([
                'success' => true,
                'data' => $exportData,
                'total' => $exportData->count()
            ]);
        } catch (\Exception $e) {
            Log::error('❌ [DonasiController] Error export', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal export donasi',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get Programs List (For Filter Dropdown)
     * GET /api/admin/donasi/programs
     */
    public function programs()
    {
        try {
            Log::info('📂 [DonasiController] programs called');

            $programs = ProgramDonasi::where('status', 'active')
                ->select('id', 'nama_program')
                ->get()
                ->map(function($program) {
                    return [
                        'id' => $program->id,
                        'name' => $program->nama_program,
                    ];
                });

            Log::info('✅ [DonasiController] Programs retrieved', [
                'count' => $programs->count(),
            ]);
            
            return response()->json([
                'success' => true,
                'data' => $programs
            ]);
        } catch (\Exception $e) {
            Log::error('❌ [DonasiController] Error programs', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil program list',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}