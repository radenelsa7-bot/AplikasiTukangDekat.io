<?php

namespace Database\Factories;

use App\Models\User;
use App\Models\ProviderPayout;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProviderPayout>
 */
class ProviderPayoutFactory extends Factory
{
  protected $model = ProviderPayout::class;

  public function definition(): array
  {
    return [
      'provider_id' => User::factory()->provider()->create()->id,
      'amount' => $this->faker->randomFloat(2, 100000, 1000000),
      'payment_ids' => [],
      'status' => 'pending',
      'sent_at' => null,
    ];
  }

  /**
   * Create a paid payout.
   */
  public function paid(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'paid',
      'sent_at' => now(),
    ]);
  }

  /**
   * Create a failed payout.
   */
  public function failed(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'failed',
    ]);
  }

  /**
   * Create a pending payout.
   */
  public function pending(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'pending',
      'sent_at' => null,
    ]);
  }
}
