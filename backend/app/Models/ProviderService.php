<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProviderService extends Model
{
  use HasFactory;

  protected $fillable = [
    'provider_profile_id',
    'category_id',
    'name',
    'description',
    'base_price',
    'price_unit',
    'is_active',
  ];

  protected $casts = [
    'is_active' => 'boolean',
    'base_price' => 'integer',
  ];

  public function provider(): BelongsTo
  {
    return $this->belongsTo(ProviderProfile::class, 'provider_profile_id');
  }

  public function category(): BelongsTo
  {
    return $this->belongsTo(ServiceCategory::class, 'category_id');
  }
}
