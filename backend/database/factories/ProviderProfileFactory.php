<?php

namespace Database\Factories;

use App\Models\ProviderProfile;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProviderProfile>
 */
class ProviderProfileFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'business_name' => $this->faker->company(),
            'description' => $this->faker->paragraph(),
            'area' => $this->faker->city(),
            'address' => $this->faker->address(),
            'is_verified' => false,
            'avg_rating' => 0.00,
        ];
    }
}
