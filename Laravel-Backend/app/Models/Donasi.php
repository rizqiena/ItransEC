<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Donasi extends Model
{
    use HasFactory;

    protected $table = 'donasis';
    
    protected $fillable = [
        'user_id',
        'user_name',
        'user_email',
        'user_phone',
        'emisi_kg',
        'nominal_donasi',
        'rate_per_kg',
        'program_id',
        'program_name',
        'transaction_id',
        'midtrans_order_id',
        'payment_method',
        'payment_status',
        'payment_time',
        'payment_response',
    ];

    protected $casts = [
        'emisi_kg' => 'decimal:2',
        'nominal_donasi' => 'decimal:2',
        'rate_per_kg' => 'decimal:2',
        'payment_time' => 'datetime',
    ];

    // Relationship dengan ProgramDonasi
    public function program()
    {
        return $this->belongsTo(ProgramDonasi::class, 'program_id', 'id');
    }
}