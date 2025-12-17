<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use Illuminate\Http\Request;

class TripController extends Controller
{
    // GET /api/trips  -> ambil semua riwayat (bisa di-filter nanti)
    public function index()
    {
        // kalau nanti ada user login, bisa pakai where('user_id', auth()->id())
        $trips = Trip::orderByDesc('started_at')
            ->orderByDesc('created_at')
            ->get();

        return response()->json($trips);
    }

    // POST /api/trips -> simpan perjalanan baru
    public function store(Request $request)
    {
        $data = $request->validate([
            'vehicle_summary'  => 'required|string',
            'distance_km'      => 'required|numeric',
            'emission_kg'      => 'required|numeric',
            'duration_seconds' => 'required|integer',

            'started_at'       => 'nullable|date',
            'ended_at'         => 'nullable|date',
            'start_lat'        => 'nullable|numeric',
            'start_lng'        => 'nullable|numeric',
            'end_lat'          => 'nullable|numeric',
            'end_lng'          => 'nullable|numeric',

            // ==== route_points (opsional) ====
            // dikirim sebagai array of { lat, lng }
            'route_points'           => 'nullable|array',
            'route_points.*.lat'     => 'required_with:route_points|numeric',
            'route_points.*.lng'     => 'required_with:route_points|numeric',
        ]);

        // kalau sudah ada auth:
        // $data['user_id'] = $request->user()->id;

        $trip = Trip::create($data);

        return response()->json($trip, 201);
    }

    /**
     * GET /api/emissions/monthly?year=2025&month=12
     * Ringkasan total emisi per bulan (sementara untuk semua user).
     * Nanti bisa ditambah filter user_id kalau auth sudah aktif.
     */
    public function monthlySummary(Request $request)
    {
        $year  = (int) $request->query('year', now()->year);
        $month = (int) $request->query('month', now()->month);

        $query = Trip::query();

        // Kalau nanti sudah ada user login:
        // $query->where('user_id', $request->user()->id);

        $totalEmission = $query
            ->whereYear('created_at', $year)
            ->whereMonth('created_at', $month)
            ->sum('emission_kg'); // pastikan nama kolom sesuai di tabel trips

        return response()->json([
            'status'            => true,
            'year'              => $year,
            'month'             => $month,
            'total_emission_kg' => (float) $totalEmission,
        ]);
    }
}
