<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Admin;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        // Cek dulu, kalau belum ada baru create
        Admin::firstOrCreate(
            ['Email_Admin' => 'admin@gmail.com'], // Cari berdasarkan email
            [
                'Nama_Admin' => 'Administrator',
                'Password_Admin' => Hash::make('admin123'),
            ]
        );
    }
}