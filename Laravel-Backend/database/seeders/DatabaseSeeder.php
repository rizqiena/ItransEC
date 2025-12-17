<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // ✅ 1. Insert Masyarakat (User)
        DB::table('masyarakat')->insert([
            [
                'Nama_Masyarakat' => 'John Doe',
                'Email_Masyarakat' => 'john@example.com',
                'KataSandi_Masyarakat' => Hash::make('password123'),
                'Nomor_HP' => '081234567890',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'Nama_Masyarakat' => 'Jane Smith',
                'Email_Masyarakat' => 'jane@example.com',
                'KataSandi_Masyarakat' => Hash::make('password123'),
                'Nomor_HP' => '089876543210',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        // ✅ 2. Insert Program Donasi
        DB::table('program_donasi')->insert([
            [
                'nama_program' => 'Tanam 1000 Pohon',
                'deskripsi' => 'Program penanaman 1000 pohon untuk mengurangi emisi karbon',
                'icon' => '🌳',
                'target_angka' => 1000,
                'target_satuan' => 'pohon',
                'progress_saat_ini' => 150,
                'target_donasi_rp' => 50000000,
                'total_donasi_masuk' => 7500000,
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'nama_program' => 'Energi Terbarukan',
                'deskripsi' => 'Instalasi panel surya untuk komunitas',
                'icon' => '☀️',
                'target_angka' => 50,
                'target_satuan' => 'panel',
                'progress_saat_ini' => 10,
                'target_donasi_rp' => 100000000,
                'total_donasi_masuk' => 20000000,
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $this->command->info('✅ Data dummy berhasil dibuat!');
    }
}