<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProviderProfile extends Model
{
  use HasFactory;

  protected $fillable = [
    'user_id',
    'business_name',
    'description',
    'area',
    'address',
    'is_verified',
    'avg_rating',
  ];

  protected $casts = [
    'is_verified' => 'boolean',
    'avg_rating' => 'decimal:2',
  ];

  public function user(): HasOne
  {
    return $this->hasOne(User::class, 'id', 'user_id');
  }

  public function services(): HasMany
  {
    return $this->hasMany(ProviderService::class);
  }

  public function reviews(): HasMany
  {
    return $this->hasMany(Review::class, 'provider_id', 'user_id');
  }
}
