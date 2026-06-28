<?php

namespace Database\Factories;

use App\Models\Order;
use App\Models\Review;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Review>
 */
class ReviewFactory extends Factory
{
    protected $model = Review::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $order = Order::factory()->completed()->create();

        return [
            'order_id' => $order->id,
            'customer_id' => $order->customer_id,
            'provider_id' => $order->provider_id,
            'rating' => $this->faker->numberBetween(3, 5),
            // Menggunakan paragraf dari branch feature agar teks ulasan lebih panjang/sesuai kebutuhan smoke test Anda
            'comment' => $this->faker->paragraph(), 
        ];
    }

    /**
     * Create a review with low rating.
     */
    public function lowRating(): static
    {
        return $this->state(fn (array $attributes) => [
            'rating' => $this->faker->numberBetween(1, 2),
        ]);
    }

    /**
     * Create a review with medium rating.
     */
    public function mediumRating(): static
    {
        return $this->state(fn (array $attributes) => [
            'rating' => $this->faker->numberBetween(3, 3),
        ]);
    }

    /**
     * Create a review with high rating.
     */
    public function highRating(): static
    {
        return $this->state(fn (array $attributes) => [
            'rating' => $this->faker->numberBetween(4, 5),
        ]);
    }

    /**
     * Create a review without comment.
     */
    public function withoutComment(): static
    {
        return $this->state(fn (array $attributes) => [
            'comment' => null,
        ]);
    }
}