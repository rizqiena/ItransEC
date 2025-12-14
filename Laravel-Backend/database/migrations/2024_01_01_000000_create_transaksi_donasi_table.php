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
        Schema::create('transaksi_donasi', function (Blueprint $table) {
            $table->id('Id_Transaksi');
            $table->unsignedBigInteger('Id_Masyarakat')->nullable();
            $table->unsignedBigInteger('Id_Donasi')->nullable(); // ID Program Donasi
            $table->string('order_id')->unique();
            $table->decimal('emisi_kg', 10, 2)->default(0);
            $table->decimal('nominal_donasi', 15, 2)->default(0);
            $table->enum('payment_status', ['pending', 'settlement', 'success', 'failed', 'expired'])->default('pending');
            $table->string('payment_type')->nullable();
            $table->text('payment_url')->nullable();
            $table->text('snap_token')->nullable();
            $table->timestamps();
            
            // Foreign keys
            $table->foreign('Id_Masyarakat')->references('Id_Masyarakat')->on('masyarakat')->onDelete('cascade');
            $table->foreign('Id_Donasi')->references('Id_Donasi')->on('program_donasi')->onDelete('set null');
            
            // Indexes
            $table->index('payment_status');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transaksi_donasi');
    }
};