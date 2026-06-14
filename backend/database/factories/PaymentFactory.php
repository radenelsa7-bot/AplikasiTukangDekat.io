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
    $amount = $this->faker->numberBetween(50000, 200000);
    $commissionPercent = 10; // 10% commission
    $platformFee = intval($amount * $commissionPercent / 100);
    $providerPayout = $amount - $platformFee;

    return [
      'order_id' => $order->id,
      'payment_type' => 'DP',
      'amount' => $this->faker->numberBetween(10000, 200000),
      'status' => 'PAID',
      'provider' => null,
      'external_payment_id' => null,
      'paid_at' => now(),
    ]);
  }

  /**
   * Create a settled payment.
   */
  public function settled(): static
  {
    return $this->paid()->state(fn (array $attributes) => [
      'settlement_status' => 'SETTLED',
      'settled_at' => now()->addDays(3),
    ]);
  }

  /**
   * Create a cancelled payment.
   */
  public function cancelled(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'CANCELLED',
    ]);
  }

  /**
   * Create a payment with refund.
   */
  public function refunded(): static
  {
    return $this->paid()->state(fn (array $attributes) => [
      'refund_amount' => $attributes['amount'] ?? $this->faker->numberBetween(50000, 200000),
      'refund_status' => 'COMPLETED',
      'refund_reason' => 'Customer request',
      'refund_requested_at' => now(),
    ]);
  }
}
