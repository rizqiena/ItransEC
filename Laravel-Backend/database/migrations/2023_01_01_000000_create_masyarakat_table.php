<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('masyarakat', function (Blueprint $table) { // ← UBAH dari 'masyarakats'
            $table->id('Id_Masyarakat');
            $table->string('Nama_Masyarakat');
            $table->string('Email_Masyarakat')->unique();
            $table->string('KataSandi_Masyarakat');
            $table->string('Profil_Masyarakat')->nullable();
            $table->string('Nomor_HP')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('masyarakat'); // ← UBAH dari 'masyarakats'
    }
};