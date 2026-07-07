<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderAttachment extends Model
{
  use HasFactory;

  protected $fillable = [
    'order_id',
    'file_url',
    'file_type',
  ];

  protected $appends = ['public_url'];

  public function order(): BelongsTo
  {
    return $this->belongsTo(Order::class);
  }

  public function getPublicUrlAttribute(): ?string
  {
    $url = $this->attributes['file_url'] ?? null;
    if (!$url) return null;

    // If it's already a full URL, return as-is
    if (str_starts_with($url, 'http://') || str_starts_with($url, 'https://')) {
      return $url;
    }

    // If it's a storage path, return the API-backed storage URL so CORS headers are applied
    return url('/api/storage/' . ltrim($url, '/'));
  }
}
