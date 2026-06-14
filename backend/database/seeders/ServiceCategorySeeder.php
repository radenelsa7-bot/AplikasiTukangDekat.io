<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ServiceCategory;

class ServiceCategorySeeder extends Seeder
{
  /**
   * Run the database seeds.
   */
  public function run(): void
  {
    $categories = [
      ['name' => 'Listrik', 'description' => 'Jasa perbaikan dan instalasi listrik'],
      ['name' => 'Plumbing', 'description' => 'Jasa perbaikan pipa dan sistem air'],
      ['name' => 'AC', 'description' => 'Jasa service dan perbaikan AC'],
      ['name' => 'Bangunan Ringan', 'description' => 'Jasa renovasi dan perbaikan bangunan'],
      ['name' => 'Servis Elektronik Rumah', 'description' => 'Jasa perbaikan peralatan elektronik rumah tangga'],
    ];

    foreach ($categories as $category) {
      ServiceCategory::updateOrCreate(
        ['name' => $category['name']],
        array_merge($category, ['is_active' => true])
      );
    }
  }
}
