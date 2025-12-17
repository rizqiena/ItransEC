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
        Schema::create('tembus_emisis', function (Blueprint $table) {
            $table->id('Id_Tebus');
            $table->unsignedBigInteger('Id_Emisi');
            $table->unsignedBigInteger('Id_Masyarakat');
            $table->unsignedBigInteger('Id_Penerima_Manfaat')->nullable();
            $table->string('Kode_Transaksi')->unique();
            $table->decimal('Jumlah_Donasi', 12, 2);
            $table->date('Tanggal_Tebus');
            $table->timestamps();

            $table->foreign('Id_Emisi')
                  ->references('Id_Emisi')
                  ->on('hasil_emisis')
                  ->onDelete('cascade');
            
            // ✅ DIPERBAIKI: 'masyarakats' → 'masyarakat'
            $table->foreign('Id_Masyarakat')
                  ->references('Id_Masyarakat')
                  ->on('masyarakat')  // ← UBAH DI SINI
                  ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tembus_emisis');
    }
};