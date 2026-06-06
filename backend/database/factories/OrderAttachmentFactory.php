<?php

namespace Database\Factories;

use App\Models\Order;
use App\Models\OrderAttachment;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<OrderAttachment>
 */
class OrderAttachmentFactory extends Factory
{
  protected $model = OrderAttachment::class;

  public function definition(): array
  {
    return [
      'order_id' => Order::factory()->create()->id,
      'file_url' => $this->faker->imageUrl(640, 480, 'technics'),
      'file_type' => 'image/jpeg',
    ];
  }

  /**
   * Create an attachment with PDF type.
   */
  public function pdf(): static
  {
    return $this->state(fn (array $attributes) => [
      'file_url' => 'https://example.com/document-' . $this->faker->uuid() . '.pdf',
      'file_type' => 'application/pdf',
    ]);
  }

  /**
   * Create an attachment with document type.
   */
  public function document(): static
  {
    return $this->state(fn (array $attributes) => [
      'file_url' => 'https://example.com/document-' . $this->faker->uuid() . '.docx',
      'file_type' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ]);
  }
}
