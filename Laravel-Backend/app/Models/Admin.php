<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class Admin extends Authenticatable
{
    use HasFactory, HasApiTokens;

    protected $table = 'admins';
    protected $primaryKey = 'Id_Admin';

    protected $fillable = [
        'Nama_Admin',
        'Email_Admin',
        'Password_Admin',
        'Profil_Admin',
    ];

    protected $hidden = [
        'Password_Admin',
    ];

    // Override default column names untuk authentication
    public function getAuthPassword()
    {
        return $this->Password_Admin;
    }
}