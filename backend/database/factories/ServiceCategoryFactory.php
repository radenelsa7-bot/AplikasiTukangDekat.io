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

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            // Menggunakan format branch Anda agar nama kategori memiliki imbuhan ' Service'
            'name' => $this->faker->word() . ' Service',
            'description' => $this->faker->sentence(),
            'is_active' => true,
        ];
    }
}