<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->string('order_id')->unique();
            $table->integer('amount');
            $table->decimal('emisi', 10, 2); // emisi dalam Kg CO2
            $table->string('customer_name');
            $table->string('email');
            $table->string('phone');
            $table->string('transaction_status')->default('pending'); // pending, settlement, cancel, expire
            $table->text('raw_response')->nullable(); // response dari Midtrans (opsional)
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};