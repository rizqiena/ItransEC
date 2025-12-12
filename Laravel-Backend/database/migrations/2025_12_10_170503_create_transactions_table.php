<?php
// database/migrations/xxxx_xx_xx_create_transactions_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->string('order_id')->unique();
            $table->string('user_id'); // Bisa integer atau string tergantung sistem
            $table->decimal('amount', 15, 2);
            $table->decimal('emisi_kg', 10, 2)->default(0); // ✅ Kolom emisi
            $table->enum('status', ['pending', 'success', 'failed'])->default('pending');
            $table->string('snap_token')->nullable();
            $table->timestamps();
            
            // Index untuk performa
            $table->index('user_id');
            $table->index('status');
            $table->index('order_id');
        });
    }

    public function down()
    {
        Schema::dropIfExists('transactions');
    }
};