<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// =======================
// 🔥 IMPORT CONTROLLERS
// =======================
use App\Http\Controllers\AuthAdminController;
use App\Http\Controllers\AuthMasyarakatController;
use App\Http\Controllers\MasyarakatController;
use App\Http\Controllers\ProfilMasyarakatController;
use App\Http\Controllers\BeritaController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ProgramDonasiController;
use App\Http\Controllers\Api\TripController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\EmisiController;
use App\Http\Controllers\DonasiController;

// ======================================================
// 🔓 PUBLIC ROUTES
// ======================================================

// ADMIN AUTH
Route::post('/admin/login', [AuthAdminController::class, 'login']);

// MASYARAKAT AUTH
Route::post('/masyarakat/register', [AuthMasyarakatController::class, 'register']);
Route::post('/masyarakat/login', [AuthMasyarakatController::class, 'login']);


// ======================================================
// 💳 MIDTRANS PAYMENT ROUTES (PUBLIC)
// ======================================================
Route::post('/create-payment', [PaymentController::class, 'createPayment']);
Route::post('/payment/create', [PaymentController::class, 'createPayment']);

// Midtrans Callback
Route::post('/midtrans/callback', [PaymentController::class, 'callback']);
Route::post('/payment/callback', [PaymentController::class, 'callback']);

// Check Payment Status
Route::get('/check-status/{orderId}', [PaymentController::class, 'checkStatus']);
Route::get('/payment/status/{orderId}', [PaymentController::class, 'checkStatus']);


// ======================================================
// 🌐 PUBLIC BERITA
// ======================================================
Route::get('/berita', [BeritaController::class, 'index']);
Route::get('/berita/{id}', [BeritaController::class, 'show']);


// ======================================================
// 🚗 I-TRANSEC (TRIPS & EMISSION)
// ======================================================
Route::get('/trips', [TripController::class, 'index']);
Route::post('/trips', [TripController::class, 'store']);
Route::get('/emissions/monthly', [TripController::class, 'monthlySummary']);


// ======================================================
// 🌱 EMISI (PUBLIC ROUTES)
// ======================================================
Route::prefix('emisi')->group(function () {
    Route::post('/store', [EmisiController::class, 'store']);
    Route::get('/total-bulan-ini', [EmisiController::class, 'getTotalBulanIni']);
    Route::post('/update-status-bayar', [EmisiController::class, 'updateStatusBayar']);
    Route::get('/riwayat-pembayaran', [EmisiController::class, 'getRiwayatPembayaran']);
});


// ======================================================
// 🎁 PROGRAM DONASI (PUBLIC - FOR USER APP)
// ======================================================
Route::get('/programs/active', [ProgramDonasiController::class, 'getActivePrograms']);
Route::get('/program-donasi', [ProgramDonasiController::class, 'index']);
Route::get('/program-donasi/{id}', [ProgramDonasiController::class, 'show']);


// ======================================================
// 🔐 PROTECTED ROUTES (AUTH REQUIRED)
// ======================================================
Route::middleware('auth:sanctum')->group(function () {

    // CURRENT USER INFO
    Route::get('/me', function (Request $request) {
        return response()->json([
            'status' => true,
            'data'   => $request->user()
        ]);
    });

    // LOGOUT
    Route::post('/logout', [AuthMasyarakatController::class, 'logout']);

    // =======================
    // 💳 PROTECTED PAYMENT ROUTES
    // =======================
    Route::prefix('payment')->group(function () {
        Route::get('/my-payments', [PaymentController::class, 'myPayments']);
        Route::get('/total-emisi', [PaymentController::class, 'getTotalEmisi']);
    });

    // Alias
    Route::get('/my-payments', [PaymentController::class, 'myPayments']);
    Route::get('/total-emisi', [PaymentController::class, 'getTotalEmisi']);

    // =======================
    // 👤 MASYARAKAT PROFILE
    // =======================
    Route::prefix('masyarakat')->group(function () {
        Route::get('/profil', [ProfilMasyarakatController::class, 'show']);
        Route::post('/profil', [ProfilMasyarakatController::class, 'update']);
        Route::post('/profil/update', [ProfilMasyarakatController::class, 'update']);
        Route::put('/change-password', [ProfilMasyarakatController::class, 'changePassword']);
    });

    // =======================
    // 👑 ADMIN ROUTES (TANPA MIDDLEWARE check.admin)
    // =======================
    Route::prefix('admin')->group(function () {

        // ==================== 🎁 DONASI ROUTES (DIPINDAHKAN KE ATAS) ====================
        Route::prefix('donasi')->group(function () {
            Route::get('/stats', [DonasiController::class, 'getStats']);
            Route::get('/list', [DonasiController::class, 'getList']);
            Route::get('/detail/{id}', [DonasiController::class, 'getDetail']);
            Route::get('/export', [DonasiController::class, 'export']);
            Route::get('/programs', [DonasiController::class, 'programs']);
        });
        
        // ==================== DASHBOARD STATS ====================
        Route::get('/stats', [DashboardController::class, 'getStats']);
        Route::get('/stats/detailed', [DashboardController::class, 'getDetailedStats']);
        Route::get('/stats/overview', [DashboardController::class, 'getOverview']);
        Route::get('/stats/monthly', [DashboardController::class, 'getMonthlyStats']);

        // ==================== CRUD MASYARAKAT ====================
        Route::prefix('masyarakat')->group(function () {
            Route::get('/', [MasyarakatController::class, 'index']);
            Route::get('/{id}', [MasyarakatController::class, 'show']);
            Route::delete('/{id}', [MasyarakatController::class, 'destroy']);
        });

        // Alias
        Route::get('/users', [MasyarakatController::class, 'index']);
        Route::get('/users/{id}', [MasyarakatController::class, 'show']);
        Route::delete('/users/{id}/delete', [MasyarakatController::class, 'destroy']);

        // ==================== CRUD BERITA ====================
        Route::prefix('berita')->group(function () {
            Route::get('/', [BeritaController::class, 'index']);
            Route::post('/', [BeritaController::class, 'store']);
            Route::post('/store', [BeritaController::class, 'store']);
            Route::get('/{id}', [BeritaController::class, 'show']);
            Route::post('/{id}', [BeritaController::class, 'update']);
            Route::post('/{id}/update', [BeritaController::class, 'update']);
            Route::delete('/{id}', [BeritaController::class, 'destroy']);
            Route::delete('/{id}/delete', [BeritaController::class, 'destroy']);
        });

        // ==================== CRUD PROGRAM DONASI ====================
        Route::prefix('program-donasi')->group(function () {
            Route::get('/', [ProgramDonasiController::class, 'index']);
            Route::post('/', [ProgramDonasiController::class, 'store']);
            Route::post('/store', [ProgramDonasiController::class, 'store']);
            Route::get('/{id}', [ProgramDonasiController::class, 'show']);
            Route::put('/{id}', [ProgramDonasiController::class, 'update']);
            Route::put('/{id}/update', [ProgramDonasiController::class, 'update']);
            Route::delete('/{id}', [ProgramDonasiController::class, 'destroy']);
            Route::delete('/{id}/delete', [ProgramDonasiController::class, 'destroy']);
        });

        // ==================== STATISTIK TAMBAHAN ====================
        Route::get('/stats/berita', [BeritaController::class, 'getBeritaCount']);
        Route::get('/stats/program-donasi', [ProgramDonasiController::class, 'getProgramDonasiCount']);

    }); // END ADMIN ROUTES

}); // END AUTH SANCTUM MIDDLEWARE


// ======================================================
// 🔍 FALLBACK ROUTE (404 Handler)
// ======================================================
Route::fallback(function () {
    return response()->json([
        'success' => false,
        'message' => 'Endpoint tidak ditemukan',
        'error' => 'Route not found'
    ], 404);
});