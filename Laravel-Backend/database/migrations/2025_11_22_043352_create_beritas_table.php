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
        Schema::create('beritas', function (Blueprint $table) {
            $table->id('Id_Berita');
            $table->unsignedBigInteger('Id_Admin');
            $table->string('Judul_Berita');
            $table->text('Deskripsi_Berita');
            $table->string('Gambar_Berita')->nullable();
            $table->date('Tanggal_Berita');
            $table->timestamps();

            $table->foreign('Id_Admin')->references('Id_Admin')->on('admins')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('beritas');
    }
};
