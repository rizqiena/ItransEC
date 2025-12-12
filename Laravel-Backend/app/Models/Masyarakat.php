<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class Masyarakat extends Authenticatable
{
    use HasFactory, HasApiTokens;

    protected $table = 'masyarakats';
    protected $primaryKey = 'Id_Masyarakat';

    protected $fillable = [
        'Nama_Masyarakat',
        'Email_Masyarakat',
        'KataSandi_Masyarakat',
        'Profil_Masyarakat',
        'Nomor_HP',
    ];

    protected $hidden = [
        'KataSandi_Masyarakat',
    ];

    public function getAuthPassword()
    {
        return $this->KataSandi_Masyarakat;
    }

    // ✅ ACCESSOR DIPERBAIKI - Return full URL untuk foto profil
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
}