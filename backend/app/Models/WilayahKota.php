<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WilayahKota extends Model
{
    use HasFactory;

    protected $table = 'wilayah_kota';

    protected $fillable = ['name'];


    public function kecamatan(): HasMany
    {
        return $this->hasMany(WilayahKecamatan::class, 'kota_id');
    }
}
