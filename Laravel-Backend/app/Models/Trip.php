<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Trip extends Model
{
    protected $fillable = [
        'user_id',
        'vehicle_summary',
        'distance_km',
        'emission_kg',
        'duration_seconds',
        'started_at',
        'ended_at',
        'start_lat',
        'start_lng',
        'end_lat',
        'end_lng',
        'route_points', // <- simpan rute (JSON)
    ];

    protected $casts = [
        'started_at'   => 'datetime',
        'ended_at'     => 'datetime',
        'route_points' => 'array', // otomatis decode/encode JSON ke array PHP
    ];
}
