<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatbotLog extends Model
{
    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'request_id',
        'user_message',
        'assistant_message',
        'order_context',
        'response_time_ms',
        'status',
        'error_code',
        'error_message',
        'retry_count',
        'tokens_used',
        'api_cost_usd',
        'metadata',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'order_context' => 'json',
        'metadata' => 'json',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Relasi ke User
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope: Filter berdasarkan status
     */
    public function scopeByStatus($query, string $status)
    {
        return $query->where('status', $status);
    }

    /**
     * Scope: Filter error logs saja
     */
    public function scopeErrors($query)
    {
        return $query->where('status', 'error');
    }

    /**
     * Scope: Filter berdasarkan error code
     */
    public function scopeByErrorCode($query, string $errorCode)
    {
        return $query->where('error_code', $errorCode);
    }

    /**
     * Scope: Filter logs dari tanggal tertentu
     */
    public function scopeFromDate($query, $date)
    {
        return $query->where('created_at', '>=', $date);
    }

    /**
     * Scope: Filter logs untuk user tertentu
     */
    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }
}
