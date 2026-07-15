<?php

namespace Database\Factories;

use App\Models\ProviderCoverage;
use App\Models\ProviderProfile;
use App\Models\WilayahKecamatan;
use App\Models\WilayahKota;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProviderCoverage>
 */
class ProviderCoverageFactory extends Factory
{
    protected $model = ProviderCoverage::class;

    public function definition(): array
    {
        return [
            'provider_profile_id' => ProviderProfile::factory(),
            'kecamatan_id' => function (): int {
                $kota = WilayahKota::query()->create([
                    'name' => $this->faker->unique()->city(),
                ]);

                return WilayahKecamatan::query()->create([
                    'kota_id' => $kota->id,
                    'name' => $this->faker->unique()->citySuffix(),
                ])->id;
            },
            'is_active' => true,
        ];
    }
}
