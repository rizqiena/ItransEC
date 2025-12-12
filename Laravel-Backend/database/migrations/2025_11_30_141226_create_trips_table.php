<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('trips', function (Blueprint $table) {
            $table->id();

            // nanti bisa dihubungkan ke tabel users (opsional)
            $table->unsignedBigInteger('user_id')->nullable();

            // ringkasan kendaraan: "Mobil · <=1300 cc · RON 92"
            $table->string('vehicle_summary');

            // jarak & emisi
            $table->double('distance_km');       // km
            $table->double('emission_kg');       // kg CO2

            // durasi perjalanan dalam detik
            $table->integer('duration_seconds');

            // waktu mulai & selesai perjalanan
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();

            // created_at & updated_at
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trips');
    }
};
