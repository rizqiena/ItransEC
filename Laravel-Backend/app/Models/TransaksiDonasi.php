<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TransaksiDonasi extends Model
{
    use HasFactory;

    protected $table = 'transaksi_donasi';
    
    protected $primaryKey = 'Id_Transaksi';
    
    public $incrementing = true;
    
    protected $fillable = [
        'Id_Masyarakat',
        'Id_Donasi',
        'order_id',
        'emisi_kg',
        'nominal_donasi',
        'payment_status',
        'payment_type',
        'payment_url',
        'snap_token',
    ];

    protected $casts = [
        'emisi_kg' => 'decimal:2',
        'nominal_donasi' => 'decimal:2',
    ];

    // Relationship ke Masyarakat
    public function masyarakat()
    {
        return $this->belongsTo(Masyarakat::class, 'Id_Masyarakat', 'Id_Masyarakat');
    }

    // Relationship ke Program Donasi
    public function programDonasi()
    {
        return $this->belongsTo(ProgramDonasi::class, 'Id_Donasi', 'Id_Donasi');
    }

    // Scope untuk filter status pembayaran
    public function scopePending($query)
    {
        return $query->where('payment_status', 'pending');
    }

    public function scopeSuccess($query)
    {
        return $query->whereIn('payment_status', ['settlement', 'success']);
    }
}