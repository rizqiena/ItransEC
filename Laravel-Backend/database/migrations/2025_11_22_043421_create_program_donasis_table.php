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
        Schema::create('program_donasis', function (Blueprint $table) {
            $table->id('Id_Donasi');
            $table->string('Judul_Program');
            $table->string('Rekening_Donasi');
            $table->decimal('Emisi_Donasi', 10, 2);
            $table->string('Nama_Perusahaan');
            $table->decimal('Target_Donasi', 12, 2);
            $table->date('Tanggal_Mulai_Donasi');
            $table->date('Tanggal_Selesai_Donasi');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('program_donasis');
    }
};
