<?php

namespace App\Http\Controllers;

use App\Models\ProgramDonasi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ProgramDonasiController extends Controller
{
    /**
     * Get active program donasi (For User App - Payment Page)
     * GET /api/programs/active
     */
    public function getActivePrograms()
    {
        try {
            Log::info('🔍 [ProgramDonasi] Starting getActivePrograms...');
            
            // ✅ Query dengan nama kolom yang benar (lowercase)
            $programs = ProgramDonasi::where('status', 'active')
                ->orderBy('nama_program', 'asc')
                ->get();
            
            Log::info('📊 [ProgramDonasi] Query result', [
                'count' => $programs->count(),
                'programs' => $programs->toArray(),
            ]);
            
            if ($programs->isEmpty()) {
                Log::warning('⚠️ [ProgramDonasi] No active programs found');
                
                return response()->json([
                    'success' => true,
                    'status' => true,
                    'data' => [],
                    'message' => 'Belum ada program donasi tersedia'
                ], 200);
            }
            
            // ✅ Map data dengan pengecekan null
            $programList = $programs->map(function($program) {
                $targetDonasi = (float) ($program->target_donasi_rp ?? 0);
                $totalTerkumpul = (float) ($program->total_donasi_masuk ?? 0);
                
                $progressPercentage = 0;
                if ($targetDonasi > 0) {
                    $progressPercentage = round(($totalTerkumpul / $targetDonasi) * 100, 1);
                }
                
                return [
                    'id' => $program->id,
                    'judul' => $program->nama_program ?? 'Program Donasi',
                    'deskripsi' => $program->deskripsi ?? '',
                    'icon' => $program->icon ?? '🌱',
                    'target_number' => $program->target_angka ?? 0,
                    'target_unit' => $program->target_satuan ?? 'pohon',
                    'current_progress' => $program->progress_saat_ini ?? 0,
                    'target_donasi' => $targetDonasi,
                    'total_terkumpul' => $totalTerkumpul,
                    'progress_percentage' => $progressPercentage,
                ];
            });
            
            Log::info('✅ [ProgramDonasi] Success', [
                'count' => $programList->count(),
            ]);
            
            return response()->json([
                'success' => true,
                'status' => true,
                'data' => $programList,
                'message' => 'Program berhasil dimuat'
            ], 200);
            
        } catch (\Exception $e) {
            Log::error('❌ [ProgramDonasi] Error getActivePrograms', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'success' => false,
                'status' => false,
                'message' => 'Gagal mengambil program aktif',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}