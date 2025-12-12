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


// ======================================================
// 🔓 PUBLIC ROUTES
// ======================================================

// ADMIN AUTH
Route::post('/admin/login', [AuthAdminController::class, 'login']);

// MASYARAKAT AUTH
Route::post('/masyarakat/register', [AuthMasyarakatController::class, 'register']);
Route::post('/masyarakat/login', [AuthMasyarakatController::class, 'login']);


// ======================================================
// 💳 MIDTRANS PAYMENT ROUTES
// ======================================================
Route::post('/create-payment', [PaymentController::class, 'createPayment']);
Route::post('/midtrans/callback', [PaymentController::class, 'midtransCallback']);
Route::get('/check-status/{orderId}', [PaymentController::class, 'checkStatus']);


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
// 🌱 EMISI (ROUTES BARU DARI CLAUDE)
// ======================================================
Route::prefix('emisi')->group(function () {
    Route::post('/store', [EmisiController::class, 'store']);
    Route::get('/total-bulan-ini', [EmisiController::class, 'getTotalBulanIni']);
    Route::post('/update-status-bayar', [EmisiController::class, 'updateStatusBayar']);
    Route::get('/riwayat-pembayaran', [EmisiController::class, 'getRiwayatPembayaran']);
});


// ======================================================
// 🔐 PROTECTED ROUTES (AUTH REQUIRED)
// ======================================================
Route::middleware('auth:sanctum')->group(function () {

    // CURRENT USER
    Route::get('/me', function (Request $request) {
        return response()->json([
            'status' => true,
            'data'   => $request->user()
        ]);
    });

    // LOGOUT
    Route::post('/logout', [AuthMasyarakatController::class, 'logout']);

    // =======================
    // 💳 PROTECTED PAYMENT
    // =======================
    Route::get('/my-payments', [PaymentController::class, 'myPayments']);
    Route::get('/total-emisi', [PaymentController::class, 'getTotalEmisi']); // tetap dipakai

    // =======================
    // 👤 MASYARAKAT
    // =======================
    Route::prefix('masyarakat')->group(function () {
        Route::get('/profil', [ProfilMasyarakatController::class, 'show']);
        Route::post('/profil', [ProfilMasyarakatController::class, 'update']);
        Route::put('/change-password', [ProfilMasyarakatController::class, 'changePassword']);
    });

    // =======================
    // 👑 ADMIN ROUTES
    // =======================
    Route::prefix('admin')->group(function () {

        // DASHBOARD STATS
        Route::get('/stats', [DashboardController::class, 'getStats']);
        Route::get('/stats/detailed', [DashboardController::class, 'getDetailedStats']);
        Route::get('/stats/overview', [DashboardController::class, 'getOverview']);
        Route::get('/stats/monthly', [DashboardController::class, 'getMonthlyStats']);

        // CRUD MASYARAKAT
        Route::get('/masyarakat', [MasyarakatController::class, 'index']);
        Route::get('/masyarakat/{id}', [MasyarakatController::class, 'show']);
        Route::delete('/masyarakat/{id}', [MasyarakatController::class, 'destroy']);

        // CRUD BERITA
        Route::post('/berita', [BeritaController::class, 'store']);
        Route::post('/berita/{id}', [BeritaController::class, 'update']);
        Route::delete('/berita/{id}', [BeritaController::class, 'destroy']);

        // CRUD PROGRAM DONASI
        Route::get('/program-donasi', [ProgramDonasiController::class, 'index']);
        Route::post('/program-donasi', [ProgramDonasiController::class, 'store']);
        Route::get('/program-donasi/{id}', [ProgramDonasiController::class, 'show']);
        Route::put('/program-donasi/{id}', [ProgramDonasiController::class, 'update']);
        Route::delete('/program-donasi/{id}', [ProgramDonasiController::class, 'destroy']);

        // STATISTIK TAMBAHAN
        Route::get('/stats/berita', [BeritaController::class, 'getBeritaCount']);
        Route::get('/stats/program-donasi', [ProgramDonasiController::class, 'getProgramDonasiCount']);
    });
}); // END AUTH SANCTUM