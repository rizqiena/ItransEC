<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Donasi;
use Carbon\Carbon;

class DonasiSeeder extends Seeder
{
    public function run()
    {
        $donasis = [
            [
                'user_id' => 1,
                'user_name' => 'Ahmad Rizki',
                'user_email' => 'ahmad@example.com',
                'user_phone' => '081234567890',
                'emisi_kg' => 12.5,
                'nominal_donasi' => 12500,
                'rate_per_kg' => 1000,
                'program_id' => 1,
                'program_name' => 'Penanaman Pohon',
                'transaction_id' => 'TRX-2024-001',
                'midtrans_order_id' => 'ORD-12345-ABCDE',
                'payment_method' => 'QRIS',
                'payment_status' => 'settlement',
                'payment_time' => Carbon::now(),
                'created_at' => Carbon::now(),
            ],
            [
                'user_id' => 2,
                'user_name' => 'Siti Nurhaliza',
                'user_email' => 'siti@example.com',
                'user_phone' => '081298765432',
                'emisi_kg' => 8.3,
                'nominal_donasi' => 8300,
                'rate_per_kg' => 1000,
                'program_id' => 2,
                'program_name' => 'Energi Terbarukan',
                'transaction_id' => 'TRX-2024-002',
                'midtrans_order_id' => 'ORD-12345-FGHIJ',
                'payment_method' => 'GoPay',
                'payment_status' => 'settlement',
                'payment_time' => Carbon::now(),
                'created_at' => Carbon::now(),
            ],
            [
                'user_id' => 3,
                'user_name' => 'Budi Santoso',
                'user_email' => 'budi@example.com',
                'user_phone' => '081277778888',
                'emisi_kg' => 25.0,
                'nominal_donasi' => 25000,
                'rate_per_kg' => 1000,
                'program_id' => 3,
                'program_name' => 'Konservasi Hutan',
                'transaction_id' => 'TRX-2024-003',
                'midtrans_order_id' => 'ORD-12345-KLMNO',
                'payment_method' => 'BCA Virtual Account',
                'payment_status' => 'pending',
                'payment_time' => null,
                'created_at' => Carbon::now(),
            ],
        ];

        foreach ($donasis as $donasi) {
            Donasi::create($donasi);
        }
    }
}