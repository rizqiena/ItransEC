<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        // Table: program_donasis (daftar program donasi)
        Schema::create('program_donasis', function (Blueprint $table) {
            $table->id();
            $table->string('nama_program');
            $table->text('deskripsi')->nullable();
            $table->string('icon')->default('🌱'); // emoji icon
            $table->integer('target_angka')->default(0);
            $table->string('target_satuan')->default('pohon'); // pohon, hektar, unit, dll
            $table->integer('progress_saat_ini')->default(0);
            $table->decimal('target_donasi_rp', 15, 2)->default(0);
            $table->decimal('total_donasi_masuk', 15, 2)->default(0);
            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->string('gambar_url')->nullable();
            $table->timestamps();
        });

        // Table: donasis (transaksi donasi dari user)
        Schema::create('donasis', function (Blueprint $table) {
            $table->id();
            
            // User Info
            $table->unsignedBigInteger('user_id')->nullable();
            $table->string('user_name');
            $table->string('user_email');
            $table->string('user_phone');
            
            // Emisi & Donasi Info
            $table->decimal('emisi_kg', 10, 2);
            $table->decimal('nominal_donasi', 15, 2);
            $table->decimal('rate_per_kg', 10, 2)->default(1000.00);
            
            // Program Info
            $table->unsignedBigInteger('program_id');
            $table->string('program_name');
            
            // Payment Info
            $table->string('transaction_id')->unique();
            $table->string('midtrans_order_id')->nullable();
            $table->string('payment_method')->nullable(); // QRIS, GoPay, BCA VA, dll
            $table->enum('payment_status', ['pending', 'settlement', 'failed', 'expired'])->default('pending');
            $table->timestamp('payment_time')->nullable();
            
            // Metadata
            $table->text('payment_response')->nullable(); // JSON response dari Midtrans
            $table->timestamps();
            
            // Foreign Keys
            $table->foreign('program_id')->references('id')->on('program_donasis')->onDelete('cascade');
            
            // Indexes
            $table->index('user_id');
            $table->index('program_id');
            $table->index('payment_status');
            $table->index('created_at');
        });
    }

    public function down()
    {
        Schema::dropIfExists('donasis');
        Schema::dropIfExists('program_donasis');
    }
};