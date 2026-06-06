<?php

namespace Database\Factories;

use App\Models\ProviderProfile;
use App\Models\ServiceCategory;
use App\Models\ProviderService;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProviderService>
 */
class ProviderServiceFactory extends Factory
{
  protected $model = ProviderService::class;

  public function definition(): array
  {
    return [
      'provider_profile_id' => ProviderProfile::factory()->create()->id,
      'category_id' => ServiceCategory::factory()->create()->id,
      'name' => $this->faker->word() . ' Service',
      'base_price' => $this->faker->numberBetween(50000, 200000),
      'price_unit' => $this->faker->randomElement(['per_hour', 'per_day', 'per_project', 'per_item']),
      'is_active' => true,
    ];
  }

  /**
   * Create an inactive service.
   */
  public function inactive(): static
  {
    return $this->state(fn (array $attributes) => [
      'is_active' => false,
    ]);
  }

  /**
   * Create a service with specific price unit.
   */
  public function priceUnit(string $unit): static
  {
    return $this->state(fn (array $attributes) => [
      'price_unit' => $unit,
    ]);
  }

  /**
   * Create a premium service with higher price.
   */
  public function premium(): static
  {
    return $this->state(fn (array $attributes) => [
      'base_price' => $this->faker->numberBetween(300000, 500000),
    ]);
  }
}
