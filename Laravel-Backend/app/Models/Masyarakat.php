<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class Masyarakat extends Authenticatable
{
    use HasFactory, HasApiTokens;

    protected $table = 'masyarakat'; // ✅ UBAH: Sesuaikan dengan migration (tunggal)
    
    protected $primaryKey = 'Id_Masyarakat';
    
    public $incrementing = true;

    protected $fillable = [
        'Nama_Masyarakat',
        'Email_Masyarakat',
        'KataSandi_Masyarakat',
        'Profil_Masyarakat',
        'Nomor_HP', // ✅ Tambahkan ini ke migration jika belum ada
    ];

    protected $hidden = [
        'KataSandi_Masyarakat',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ✅ Method untuk authentication
    public function getAuthPassword()
    {
        return $this->KataSandi_Masyarakat;
    }

    // ✅ Accessor untuk foto profil
    public function getProfilMasyarakatAttribute($value)
    {
        if ($value) {
            // Jika sudah full URL, return langsung
            if (str_starts_with($value, 'http')) {
                return $value;
            }
            // Jika path relatif, buat full URL
            return url('storage/' . $value);
        }
        return null;
    }

    // ✅ Relationship ke TransaksiDonasi
    public function transaksiDonasi()
    {
        return $this->hasMany(TransaksiDonasi::class, 'Id_Masyarakat', 'Id_Masyarakat');
    }

    // ✅ Relationship ke Personal Access Tokens (jika pakai Sanctum)
    public function personalAccessTokens()
    {
        return $this->morphMany(PersonalAccessToken::class, 'tokenable');
    }
}