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
        'kota_id',
        'kecamatan_id',
        'schedule_at',
        'address',
        'notes',
        'estimated_price',
        'final_price',
        'status',
    ];

    protected $casts = [
        'schedule_at' => 'datetime',
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

    public function kota(): BelongsTo
    {
        return $this->belongsTo(WilayahKota::class, 'kota_id');
    }

    public function kecamatan(): BelongsTo
    {
        return $this->belongsTo(WilayahKecamatan::class, 'kecamatan_id');
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
    // NOTE: Tidak bergantung pada created_at karena saat test/insert cepat bisa menyebabkan duplikasi.
    // Menggunakan timestamp + random/entropy yang memastikan uniqueness.
    public static function generateCode(): string
    {
        $date = now()->format('Ymd');
        $suffix = bin2hex(random_bytes(4)); // 8 hex chars
        return 'ORD-' . $date . '-' . $suffix;
    }
}
