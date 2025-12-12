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
        Schema::create('hasil_emisis', function (Blueprint $table) {
            $table->id('Id_Emisi');
            $table->unsignedBigInteger('Id_Perjalanan');
            $table->decimal('Faktor_Emisi', 10, 4);
            $table->decimal('Total_Emisi', 10, 4);
            $table->date('Tanggal_Dihitung');
            $table->string('Jenis_Kendaraan');
            $table->timestamps();

            $table->foreign('Id_Perjalanan')->references('Id_Perjalanan')->on('perjalanans')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('hasil_emisis');
    }
};
