<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProgramDonasi extends Model
{
    use HasFactory;

    protected $table = 'program_donasi'; // ← Nama tabel (tunggal)
    
    protected $primaryKey = 'Id_Donasi'; // ← Primary key
    
    public $incrementing = true;
    
    protected $fillable = [
        'nama_program',
        'deskripsi',
        'icon',
        'target_angka',
        'target_satuan',
        'progress_saat_ini',
        'target_donasi_rp',
        'total_donasi_masuk',
        'status',
        'gambar_url',
    ];

    protected $casts = [
        'target_angka' => 'integer',
        'progress_saat_ini' => 'integer',
        'target_donasi_rp' => 'decimal:2',
        'total_donasi_masuk' => 'decimal:2',
    ];

    // Relationship dengan transaksi_donasi
    public function transaksiDonasi()
    {
        return $this->hasMany(TransaksiDonasi::class, 'Id_Donasi', 'Id_Donasi');
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }
}