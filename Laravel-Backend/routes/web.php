<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DonasiController;

// ==================== ROUTE YANG SUDAH ADA ====================
Route::get('/', function () {
    return view('welcome');
});

Route::get('/admin/dashboard', function () {
    return view('admin.dashboard');
})->middleware(['auth', 'admin']);

// ==================== ADMIN DONASI ROUTES (WEB) ====================
Route::prefix('admin')->middleware(['auth', 'admin'])->group(function () {
    
    // Dashboard Donasi - LIST
    Route::get('/donasi', [DonasiController::class, 'adminIndex'])->name('admin.donasi.index');
    
    // Kelola Program - HARUS DI ATAS /donasi/{id}
    Route::get('/donasi/programs', [DonasiController::class, 'adminPrograms'])->name('admin.donasi.programs');
    Route::post('/donasi/programs/store', [DonasiController::class, 'adminStoreProgram'])->name('admin.donasi.programs.store');
    Route::put('/donasi/programs/{id}/update', [DonasiController::class, 'adminUpdateProgram'])->name('admin.donasi.programs.update');
    Route::delete('/donasi/programs/{id}/delete', [DonasiController::class, 'adminDeleteProgram'])->name('admin.donasi.programs.delete');
    
    // Detail Donasi - HARUS DI BAWAH routes yang spesifik
    Route::get('/donasi/detail/{id}', [DonasiController::class, 'adminDetail'])->name('admin.donasi.detail');
});