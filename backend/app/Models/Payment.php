<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    use HasFactory;

  protected $fillable = [
    'order_id',
    'payment_type',
    'amount',
    'commission_percent',
    'platform_fee',
    'provider_payout',
    'settlement_status',
    'settled_at',
    'refund_amount',
    'refund_status',
    'refund_reason',
    'refund_requested_at',
    'status',
    'provider',
    'external_payment_id',
    'paid_at',
  ];

    protected $casts = [
        'amount' => 'integer',
        'commission_percent' => 'integer',
        'platform_fee' => 'integer',
        'provider_payout' => 'integer',
        'paid_at' => 'datetime',
        'qris_captured_at' => 'datetime',
        'settled_at' => 'datetime',
        'refund_amount' => 'integer',
        'refund_requested_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
