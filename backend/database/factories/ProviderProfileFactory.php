<?php

namespace Database\Factories;

use App\Models\ProviderProfile;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProviderProfile>
 */
class ProviderProfileFactory extends Factory
{
    protected $model = ProviderProfile::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory()->provider()->create()->id,
            'business_name' => $this->faker->company(),
            'description' => $this->faker->paragraph(),
            'area' => $this->faker->city(),
            'address' => $this->faker->address(),
            // Menggunakan default dari branch feature (false & 0) agar testing smoke aman
            'is_verified' => false, 
            'avg_rating' => 0.00,
        ];
    }

    /**
     * Create a verified provider.
     */
    public function verified(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_verified' => true,
            'avg_rating' => $this->faker->randomFloat(2, 0, 5),
        ]);
    }

    /**
     * Create an unverified provider.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_verified' => false,
            'avg_rating' => 0,
        ]);
    }

    /**
     * Create a provider with high rating.
     */
    public function highRating(): static
    {
        return $this->state(fn (array $attributes) => [
            'avg_rating' => $this->faker->randomFloat(2, 4, 5),
        ]);
    }

    /**
     * Create a provider with low rating.
     */
    public function lowRating(): static
    {
        return $this->state(fn (array $attributes) => [
            'avg_rating' => $this->faker->randomFloat(2, 1, 2.5),
        ]);
    }
}