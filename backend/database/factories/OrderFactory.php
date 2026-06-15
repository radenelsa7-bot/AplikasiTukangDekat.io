<?php

namespace Database\Factories;

use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Order>
 */
class OrderFactory extends Factory
{
  protected $model = Order::class;

  public function definition(): array
  {
    $customer = User::factory()->customer()->create();
    $provider = User::factory()->provider()->create();

    return [
      'order_code' => 'ORD-' . now()->format('Ymd') . '-' . str_pad(rand(1, 9999), 4, '0', STR_PAD_LEFT),
      'customer_id' => $customer->id,
      'provider_id' => $provider->id,
      'category_id' => null,
      'provider_service_id' => null,
      'schedule_at' => now()->addDays(1),
      'address' => $this->faker->address(),
      'notes' => $this->faker->sentence(),
      'estimated_price' => $this->faker->numberBetween(50000, 200000),
      'final_price' => null,
      'status' => 'CREATED',
    ];
  }

  /**
   * Create an order in ASSIGNED status.
   */
  public function assigned(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'ASSIGNED',
    ]);
  }

  /**
   * Create an order in STARTED status.
   */
  public function started(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'STARTED',
    ]);
  }

  /**
   * Create a completed order with final_price set.
   */
  public function completed(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'COMPLETED',
      'final_price' => $attributes['estimated_price'] ?? $this->faker->numberBetween(50000, 200000),
    ]);
  }

  /**
   * Create a cancelled order.
   */
  public function cancelled(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'CANCELLED',
    ]);
  }
}
