<?php

namespace Database\Factories;

use App\Models\NotificationLog;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<NotificationLog>
 */
class NotificationLogFactory extends Factory
{
  protected $model = NotificationLog::class;

  public function definition(): array
  {
    return [
      'event_name' => $this->faker->word() . '_event',
      'channel' => $this->faker->randomElement(['email', 'sms', 'in_app', 'webhook']),
      'payload_json' => json_encode([
        'message' => $this->faker->sentence(),
        'timestamp' => now()->toIso8601String(),
      ]),
      'status' => $this->faker->randomElement(['PENDING', 'SENT', 'FAILED']),
      'sent_at' => $this->faker->optional()->dateTime(),
    ];
  }

  /**
   * Indicate that the notification was sent successfully.
   */
  public function sent(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'SENT',
      'sent_at' => now(),
    ]);
  }

  /**
   * Indicate that the notification failed to send.
   */
  public function failed(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'FAILED',
      'sent_at' => null,
    ]);
  }

  /**
   * Indicate that the notification is pending.
   */
  public function pending(): static
  {
    return $this->state(fn (array $attributes) => [
      'status' => 'PENDING',
      'sent_at' => null,
    ]);
  }
}
