<?php

namespace Database\Factories;

use App\Models\ServiceCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ServiceCategory>
 */
class ServiceCategoryFactory extends Factory
{
  protected $model = ServiceCategory::class;

  public function definition(): array
  {
    return [
      'name' => $this->faker->word(),
      'description' => $this->faker->sentence(),
      'is_active' => true,
    ];
  }
}
