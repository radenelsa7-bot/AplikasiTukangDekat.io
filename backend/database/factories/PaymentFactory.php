<?php

namespace Database\Factories;

use App\Models\Order;
use App\Models\Payment;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Payment>
 */
class PaymentFactory extends Factory
{
  protected $model = Payment::class;

  public function definition(): array
  {
    $order = Order::factory()->create();

    return [
      'order_id' => $order->id,
      'payment_type' => 'DP',
      'amount' => $this->faker->numberBetween(10000, 200000),
      'status' => 'PAID',
      'provider' => null,
      'external_payment_id' => null,
      'paid_at' => now(),
    ];
  }
}
