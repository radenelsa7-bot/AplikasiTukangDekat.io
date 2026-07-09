<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_code',
        'customer_id',
        'provider_id',
        'category_id',
        'provider_service_id',
        'schedule_at',
        'address',
        'customer_latitude',
        'customer_longitude',
        'provider_latitude',
        'provider_longitude',
        'notes',
        'damage_level',
        'damage_description',
        'estimated_price_min',
        'estimated_price_max',
        'estimated_price',
        'final_price',
        'status',
        'queue_note',
    ];

    protected $casts = [
        'schedule_at' => 'datetime',
        'customer_latitude' => 'decimal:7',
        'customer_longitude' => 'decimal:7',
        'provider_latitude' => 'decimal:7',
        'provider_longitude' => 'decimal:7',
        'estimated_price_min' => 'integer',
        'estimated_price_max' => 'integer',
        'estimated_price' => 'integer',
        'final_price' => 'integer',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function provider(): BelongsTo
    {
        return $this->belongsTo(User::class, 'provider_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class, 'category_id');
    }

    public function service(): BelongsTo
    {
        return $this->belongsTo(ProviderService::class, 'provider_service_id');
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(OrderAttachment::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function review()
    {
        return $this->hasOne(Review::class);
    }

    public function statusLogs(): HasMany
    {
        return $this->hasMany(OrderStatusLog::class);
    }

    // Helper method untuk generate order code
    public static function generateCode(): string
    {
        $date = now()->format('Ymd');
        $lastOrder = self::whereDate('created_at', now())->latest('id')->first();
        $sequence = $lastOrder ? intval(substr($lastOrder->order_code, -4)) + 1 : 1;
        return 'ORD-' . $date . '-' . str_pad($sequence, 4, '0', STR_PAD_LEFT);
    }
}
