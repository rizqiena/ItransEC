<?php
// app/Models/Transaction.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $fillable = [
        'order_id',
        'user_id',
        'amount',
        'emisi_kg', // ✅ Tambah ini
        'status',
        'snap_token',
    ];

    protected $casts = [
        'amount' => 'float',
        'emisi_kg' => 'float', // ✅ Tambah ini
    ];

    // Relasi ke tabel emisi (opsional)
    public function emisi()
    {
        return $this->hasMany(Emisi::class, 'Id_Masyarakat', 'user_id');
    }
}