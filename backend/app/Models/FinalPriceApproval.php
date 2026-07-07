<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FinalPriceApproval extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'proposed_final_price',
        'approval_status',
        'approved_by',
    ];

    protected $casts = [
        'proposed_final_price' => 'integer',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }
}
