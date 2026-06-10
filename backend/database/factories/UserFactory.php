<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'phone' => fake()->numerify('+62###########'),
            'password' => static::$password ??= Hash::make('password'),
            'role' => fake()->randomElement(['CUSTOMER', 'PROVIDER']),
            'status' => 'ACTIVE',
            'email_verified_at' => now(),
            'remember_token' => Str::random(10),
        ];
    }

    /**
     * Indicate that the model's email address should be unverified.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }

    /**
     * Create a customer user.
     */
    public function customer(): static
    {
        return $this->state(fn (array $attributes) => [
            'role' => 'CUSTOMER',
        ]);
    }

    /**
     * Create a provider user.
     */
    public function provider(): static
    {
        return $this->state(fn (array $attributes) => [
            'role' => 'PROVIDER',
        ]);
    }

    /**
     * Create an inactive user.
     */
    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'INACTIVE',
        ]);
    }
}
