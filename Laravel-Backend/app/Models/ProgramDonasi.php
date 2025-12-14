<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProgramDonasi extends Model
{
    use HasFactory;

    protected $table = 'program_donasis';
    
    // ✅ PRIMARY KEY: 'id' (lowercase, sesuai screenshot)
    protected $primaryKey = 'id';
    
    public $incrementing = true;
    
    // ✅ KOLOM SESUAI DATABASE (lowercase semua)
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

    // Relationship
    public function donasis()
    {
        return $this->hasMany(Donasi::class, 'program_id', 'id');
    }

    // Scope untuk program aktif
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }
}