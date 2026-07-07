<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WilayahKecamatan extends Model
{
    use HasFactory;

    protected $fillable = [
        'kota_id',
        'name',
    ];

    public function kota(): BelongsTo
    {
        return $this->belongsTo(WilayahKota::class, 'kota_id');
    }

    public function providerCoverages(): HasMany
    {
        return $this->hasMany(ProviderCoverage::class, 'kecamatan_id');
    }
}
