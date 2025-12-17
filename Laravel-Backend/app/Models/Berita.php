<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Berita extends Model
{
    use HasFactory;

    protected $table = 'beritas';
    protected $primaryKey = 'Id_Berita';

    protected $fillable = [
        'Id_Admin',
        'Judul_Berita',
        'Deskripsi_Berita',
        'Gambar_Berita',
        'Tanggal_Berita',
    ];

    protected $casts = [
        'Tanggal_Berita' => 'date',
    ];

    // Relasi ke Admin
    public function admin()
    {
        return $this->belongsTo(Admin::class, 'Id_Admin', 'Id_Admin');
    }

    // Accessor untuk URL gambar lengkap
    public function getGambarUrlAttribute()
    {
        if ($this->Gambar_Berita) {
            return url('storage/berita/' . $this->Gambar_Berita);
        }
        return null;
    }
}