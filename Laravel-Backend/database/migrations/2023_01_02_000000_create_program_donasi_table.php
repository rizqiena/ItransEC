<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('program_donasi', function (Blueprint $table) {
            $table->id('Id_Donasi');
            $table->string('nama_program');
            $table->text('deskripsi')->nullable();
            $table->string('icon')->nullable();
            $table->integer('target_angka')->default(0);
            $table->string('target_satuan')->nullable();
            $table->integer('progress_saat_ini')->default(0);
            $table->decimal('target_donasi_rp', 15, 2)->default(0);
            $table->decimal('total_donasi_masuk', 15, 2)->default(0);
            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->string('gambar_url')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('program_donasi');
    }
};
