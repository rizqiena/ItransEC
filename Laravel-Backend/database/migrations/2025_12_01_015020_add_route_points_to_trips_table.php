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
        Schema::table('trips', function (Blueprint $table) {
            // TARUH DI SINI 👇
            // kalau di tabel kamu ada kolom 'end_lng', pakai after('end_lng')
            $table->longText('route_points')->nullable()->after('end_lng');

            // kalau TIDAK ada end_lng, pakai ini saja:
            // $table->longText('route_points')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('trips', function (Blueprint $table) {
            $table->dropColumn('route_points');
        });
    }
};
