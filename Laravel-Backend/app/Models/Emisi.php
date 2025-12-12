<?php
// app/Models/Emisi.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Emisi extends Model
{
    protected $table = 'emisi';
    protected $primaryKey = 'Id_Emisi';
    
    protected $fillable = [
        'Id_Masyarakat',
        'Emisi_Kg',
        'Jarak_Km',
        'Durasi_Menit',
        'Jenis_Kendaraan',
        'Tanggal_Perjalanan',
        'Status_Bayar'
    ];

    protected $casts = [
        'Emisi_Kg' => 'float',
        'Jarak_Km' => 'float',
        'Tanggal_Perjalanan' => 'datetime',
        'Status_Bayar' => 'boolean',
    ];
}