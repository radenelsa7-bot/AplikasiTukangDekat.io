<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ProviderProfile extends Model
{
  use HasFactory;

  protected $fillable = [
    'user_id',
    'business_name',
    'description',
    'area',
    'address',
    'latitude',
    'longitude',
    'is_verified',
    'is_active',
    'avg_rating',
    'availability_status',
  ];

  protected $casts = [
    'is_verified' => 'boolean',
    'is_active' => 'boolean',
    'avg_rating' => 'decimal:2',
    'latitude' => 'decimal:7',
    'longitude' => 'decimal:7',
  ];

  public function user(): HasOne
  {
    return $this->hasOne(User::class, 'id', 'user_id');
  }

  public function services(): HasMany
  {
    return $this->hasMany(ProviderService::class);
  }

  public function coverages(): HasMany
  {
    return $this->hasMany(ProviderCoverage::class, 'provider_profile_id');
  }

  public function reviews(): HasMany
  {
    return $this->hasMany(Review::class, 'provider_id', 'user_id');
  }
}
