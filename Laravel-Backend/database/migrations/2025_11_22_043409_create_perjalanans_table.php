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
        Schema::create('perjalanans', function (Blueprint $table) {
            $table->id('Id_Perjalanan');
            $table->unsignedBigInteger('Id_Masyarakat');
            $table->string('Tujuan_Perjalanan');
            $table->decimal('Jarak_Km', 8, 2);
            $table->string('Jenis_Kendaraan');
            $table->date('Tanggal_Perjalanan');
            $table->timestamps();

            // ✅ UBAH INI: 'masyarakats' → 'masyarakat'
            $table->foreign('Id_Masyarakat')
                  ->references('Id_Masyarakat')
                  ->on('masyarakat')  // ← DIPERBAIKI DI SINI
                  ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('perjalanans');
    }
};