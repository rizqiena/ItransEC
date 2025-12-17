<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('trips', function (Blueprint $table) {
            $table->double('start_lat')->nullable()->after('duration_seconds');
            $table->double('start_lng')->nullable()->after('start_lat');
            $table->double('end_lat')->nullable()->after('start_lng');
            $table->double('end_lng')->nullable()->after('end_lat');
        });
    }

    public function down(): void
    {
        Schema::table('trips', function (Blueprint $table) {
            $table->dropColumn(['start_lat', 'start_lng', 'end_lat', 'end_lng']);
        });
    }
};
