<?php

namespace Database\Factories;

use App\Models\ProviderPayout;
use App\Models\ProviderPayoutAttempt;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProviderPayoutAttempt>
 */
class ProviderPayoutAttemptFactory extends Factory
{
  protected $model = ProviderPayoutAttempt::class;

  public function definition(): array
  {
    return [
      'provider_payout_id' => ProviderPayout::factory()->create()->id,
      'status' => 'PENDING',
      'transaction_reference' => $this->faker->uuid(),
      'error_message' => null,
      'meta' => [
        'provider' => 'xendit',
        'request_id' => $this->faker->uuid(),
      ],
    ];
  }

  /**
   * Create a successful attempt.
   */
  public function success(): static
  {
    return $this->state(fn(array $attributes) => [
      'status' => 'SENT',
      'error_message' => null,
    ]);
  }

  /**
   * Create a failed attempt.
   */
  public function failed(): static
  {
    return $this->state(fn(array $attributes) => [
      'status' => 'FAILED',
      'error_message' => $this->faker->randomElement([
        'Insufficient balance',
        'Invalid account',
        'Network timeout',
        'Invalid amount',
      ]),
    ]);
  }

  /**
   * Create a pending attempt.
   */
  public function pending(): static
  {
    return $this->state(fn(array $attributes) => [
      'status' => 'PENDING',
      'error_message' => null,
    ]);
  }
}
