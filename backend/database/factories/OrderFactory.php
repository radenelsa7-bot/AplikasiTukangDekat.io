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
    $customer = User::factory()->create(['role' => 'CUSTOMER']);
    $provider = User::factory()->create(['role' => 'PROVIDER']);

    return [
      'order_code' => 'ORD-' . now()->format('Ymd') . '-' . rand(1000, 9999),
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
}
