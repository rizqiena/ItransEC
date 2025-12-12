<?php
// app/Models/TembusEmisi.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TembusEmisi extends Model
{
    protected $table = 'tembus_emisis';
    protected $primaryKey = 'Id_Tebus';
    
    protected $fillable = [
        'Id_Emisi',
        'Id_Masyarakat',
        'Id_Penerima_Manfaat',
        'Kode_Transaksi',
        'Jumlah_Donasi',
        'Tanggal_Tebus'
    ];

    protected $casts = [
        'Jumlah_Donasi' => 'float',
        'Tanggal_Tebus' => 'date',
    ];

    // Relasi ke tabel emisi
    public function emisi()
    {
        return $this->belongsTo(Emisi::class, 'Id_Emisi', 'Id_Emisi');
    }
}