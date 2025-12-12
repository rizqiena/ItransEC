<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $fillable = [
        'order_id',
        'amount',
        'emisi',
        'customer_name',
        'email',
        'phone',
        'transaction_status',
        'raw_response',
    ];

    protected $casts = [
        'amount' => 'integer',
        'emisi' => 'decimal:2',
    ];
}