<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Masyarakat;
use App\Models\Berita;
use App\Models\ProgramDonasi;

class DashboardController extends Controller
{
    /**
     * ✅ GET DASHBOARD STATS (BASIC)
     * Endpoint: GET /api/admin/stats
     */
    public function getStats(Request $request)
    {
        try {
            $stats = [
                'total_user' => Masyarakat::count(),
                'total_berita' => Berita::count(),
                'total_penerima' => ProgramDonasi::count(),
                'active_penerima' => ProgramDonasi::active()->count(),
            ];

            return response()->json([
                'status' => true,
                'message' => 'Data statistik dashboard berhasil diambil',
                'data' => $stats
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil statistik: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * ✅ GET DETAILED DASHBOARD INFO (LENGKAP)
     * Endpoint: GET /api/admin/stats/detailed
     */
    public function getDetailedStats(Request $request)
    {
        try {
            $currentMonth = now()->month;
            $currentYear = now()->year;

            // User Stats
            $userStats = [
                'total' => Masyarakat::count(),
                'new_this_month' => Masyarakat::whereMonth('Created_At', $currentMonth)
                    ->whereYear('Created_At', $currentYear)
                    ->count(),
            ];

            // Berita Stats
            $beritaStats = [
                'total' => Berita::count(),
                'this_month' => Berita::whereMonth('Created_At', $currentMonth)
                    ->whereYear('Created_At', $currentYear)
                    ->count(),
                'latest' => Berita::orderBy('Created_At', 'desc')
                    ->take(5)
                    ->get(['Id_Berita', 'Judul_Berita', 'Isi_Berita', 'Gambar_Berita', 'Created_At']),
            ];

            // Program Donasi Stats
            $programStats = [
                'total' => ProgramDonasi::count(),
                'active' => ProgramDonasi::active()->count(),
                'this_month' => ProgramDonasi::whereMonth('created_at', $currentMonth)
                    ->whereYear('created_at', $currentYear)
                    ->count(),
                'total_target' => ProgramDonasi::sum('Target_Donasi'),
                'total_collected' => ProgramDonasi::sum('Emisi_Donasi'),
                'latest' => ProgramDonasi::orderBy('created_at', 'desc')
                    ->take(5)
                    ->get(),
            ];

            $overallProgress = $programStats['total_target'] > 0 
                ? ($programStats['total_collected'] / $programStats['total_target']) * 100 
                : 0;

            return response()->json([
                'status' => true,
                'message' => 'Data statistik detail berhasil diambil',
                'data' => [
                    'users' => $userStats,
                    'berita' => $beritaStats,
                    'program_donasi' => $programStats,
                    'overall_progress' => round($overallProgress, 2),
                    'summary' => [
                        'total_users' => $userStats['total'],
                        'total_berita' => $beritaStats['total'],
                        'total_programs' => $programStats['total'],
                        'active_programs' => $programStats['active'],
                    ]
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil statistik detail: ' . $e->getMessage(),
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * ✅ GET DASHBOARD OVERVIEW (MEDIUM DETAIL)
     * Endpoint: GET /api/admin/stats/overview
     */
    public function getOverview(Request $request)
    {
        try {
            $overview = [
                'counts' => [
                    'users' => Masyarakat::count(),
                    'berita' => Berita::count(),
                    'programs' => ProgramDonasi::count(),
                    'active_programs' => ProgramDonasi::active()->count(),
                ],

                'recent_berita' => Berita::orderBy('Created_At', 'desc')
                    ->take(3)
                    ->get(['Id_Berita', 'Judul_Berita', 'Created_At']),

                'recent_programs' => ProgramDonasi::orderBy('created_at', 'desc')
                    ->take(3)
                    ->get([
                        'Id_Donasi',
                        'Judul_Program',
                        'Nama_Perusahaan',
                        'Target_Donasi',
                        'Emisi_Donasi',
                        'created_at'
                    ]),

                'financial_summary' => [
                    'total_target' => ProgramDonasi::sum('Target_Donasi'),
                    'total_collected' => ProgramDonasi::sum('Emisi_Donasi'),
                ],
            ];

            $overview['financial_summary']['progress_percentage'] = 
                $overview['financial_summary']['total_target'] > 0
                    ? round(($overview['financial_summary']['total_collected'] / 
                            $overview['financial_summary']['total_target']) * 100, 2)
                    : 0;

            return response()->json([
                'status' => true,
                'message' => 'Data overview dashboard berhasil diambil',
                'data' => $overview
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil overview: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * ✅ GET MONTHLY STATISTICS
     * Endpoint: GET /api/admin/stats/monthly
     */
    public function getMonthlyStats(Request $request)
    {
        try {
            $year = $request->input('year', now()->year);
            
            $monthlyData = [];
            
            for ($month = 1; $month <= 12; $month++) {
                $monthlyData[] = [
                    'month' => $month,
                    'month_name' => date('F', mktime(0, 0, 0, $month, 1)),
                    'new_users' => Masyarakat::whereMonth('Created_At', $month)
                        ->whereYear('Created_At', $year)
                        ->count(),
                    'new_berita' => Berita::whereMonth('Created_At', $month)
                        ->whereYear('Created_At', $year)
                        ->count(),
                    'new_programs' => ProgramDonasi::whereMonth('created_at', $month)
                        ->whereYear('created_at', $year)
                        ->count(),
                ];
            }

            return response()->json([
                'status' => true,
                'message' => 'Data statistik bulanan berhasil diambil',
                'data' => [
                    'year' => $year,
                    'monthly_stats' => $monthlyData
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil statistik bulanan: ' . $e->getMessage()
            ], 500);
        }
    }
}