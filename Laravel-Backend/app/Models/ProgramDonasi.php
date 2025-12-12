<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProgramDonasi extends Model
{
    use HasFactory;

    protected $table = 'program_donasis';
    protected $primaryKey = 'Id_Donasi';

    protected $fillable = [
        'Judul_Program',
        'Rekening_Donasi',
        'Emisi_Donasi',
        'Nama_Perusahaan',
        'Target_Donasi',
        'Tanggal_Mulai_Donasi',
        'Tanggal_Selesai_Donasi',
    ];

    protected $casts = [
        'Emisi_Donasi' => 'decimal:2',
        'Target_Donasi' => 'decimal:2',
        'Tanggal_Mulai_Donasi' => 'date',
        'Tanggal_Selesai_Donasi' => 'date',
    ];

    /**
     * Get total terkumpul (Emisi_Donasi sebagai total terkumpul)
     */
    public function getTotalTerkumpulAttribute()
    {
        return $this->Emisi_Donasi;
    }

    /**
     * Get persentase progress donasi
     */
    public function getPersentaseProgressAttribute()
    {
        if ($this->Target_Donasi <= 0) {
            return 0;
        }
        return min(100, ($this->Emisi_Donasi / $this->Target_Donasi) * 100);
    }

    /**
     * Check if program is active
     */
    public function getIsActiveAttribute()
    {
        $now = now();
        return $now->between($this->Tanggal_Mulai_Donasi, $this->Tanggal_Selesai_Donasi);
    }

    /**
     * Scope untuk program yang sedang aktif
     */
    public function scopeActive($query)
    {
        $now = now();
        return $query->where('Tanggal_Mulai_Donasi', '<=', $now)
                     ->where('Tanggal_Selesai_Donasi', '>=', $now);
    }
}