<?php
// app/Http/Controllers/EmisiController.php
namespace App\Http\Controllers;

use App\Models\Emisi;
use App\Models\TembusEmisi;
use Illuminate\Http\Request;
use Carbon\Carbon;

class EmisiController extends Controller
{
    // Simpan emisi setelah perjalanan selesai
    public function store(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required',
            'emisi_kg' => 'required|numeric',
            'jarak_km' => 'required|numeric',
            'durasi_menit' => 'required|integer',
            'jenis_kendaraan' => 'required|string',
        ]);

        $emisi = Emisi::create([
            'Id_Masyarakat' => $validated['user_id'],
            'Emisi_Kg' => $validated['emisi_kg'],
            'Jarak_Km' => $validated['jarak_km'],
            'Durasi_Menit' => $validated['durasi_menit'],
            'Jenis_Kendaraan' => $validated['jenis_kendaraan'],
            'Tanggal_Perjalanan' => now(),
            'Status_Bayar' => false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Emisi berhasil disimpan',
            'data' => $emisi
        ]);
    }

    // Get total emisi bulan ini (belum dibayar)
    public function getTotalBulanIni(Request $request)
    {
        $userId = $request->input('user_id');
        
        $totalEmisi = Emisi::where('Id_Masyarakat', $userId)
            ->where('Status_Bayar', false)
            ->whereYear('Tanggal_Perjalanan', Carbon::now()->year)
            ->whereMonth('Tanggal_Perjalanan', Carbon::now()->month)
            ->sum('Emisi_Kg');

        return response()->json([
            'success' => true,
            'total_emisi_kg' => round($totalEmisi, 2),
            'bulan' => Carbon::now()->format('F Y'),
        ]);
    }

    // Proses pembayaran tembus emisi
    public function bayarTembusEmisi(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required',
            'jumlah_donasi' => 'required|numeric',
            'id_penerima_manfaat' => 'nullable',
        ]);

        $userId = $validated['user_id'];
        
        // Ambil semua emisi yang belum dibayar bulan ini
        $emisiList = Emisi::where('Id_Masyarakat', $userId)
            ->where('Status_Bayar', false)
            ->whereYear('Tanggal_Perjalanan', Carbon::now()->year)
            ->whereMonth('Tanggal_Perjalanan', Carbon::now()->month)
            ->get();

        if ($emisiList->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada emisi yang perlu dibayar'
            ], 400);
        }

        // Generate kode transaksi unik
        $kodeTransaksi = 'TRX' . date('YmdHis') . rand(1000, 9999);

        // Simpan transaksi tembus emisi
        $tembusEmisi = TembusEmisi::create([
            'Id_Emisi' => $emisiList->first()->Id_Emisi, // atau bisa null jika multi emisi
            'Id_Masyarakat' => $userId,
            'Id_Penerima_Manfaat' => $validated['id_penerima_manfaat'] ?? null,
            'Kode_Transaksi' => $kodeTransaksi,
            'Jumlah_Donasi' => $validated['jumlah_donasi'],
            'Tanggal_Tebus' => now(),
        ]);

        // Update status bayar semua emisi
        Emisi::where('Id_Masyarakat', $userId)
            ->where('Status_Bayar', false)
            ->whereYear('Tanggal_Perjalanan', Carbon::now()->year)
            ->whereMonth('Tanggal_Perjalanan', Carbon::now()->month)
            ->update(['Status_Bayar' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Pembayaran berhasil',
            'data' => $tembusEmisi
        ]);
    }

    // Get riwayat pembayaran
    public function getRiwayatPembayaran(Request $request)
    {
        $userId = $request->input('user_id');
        
        $riwayat = TembusEmisi::where('Id_Masyarakat', $userId)
            ->orderBy('Tanggal_Tebus', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $riwayat
        ]);
    }
}