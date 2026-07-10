<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ServiceCategory extends Model
{
  use HasFactory;

  protected $fillable = [
    'name',
    'damage_severity',
    'description',
    'is_active',
  ];

  protected $casts = [
    'is_active' => 'boolean',
  ];

  public function providerServices(): HasMany
  {
    return $this->hasMany(ProviderService::class, 'category_id');
  }
}
