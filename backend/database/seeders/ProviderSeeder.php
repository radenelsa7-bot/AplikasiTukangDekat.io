<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\ProviderProfile;
use App\Models\ProviderService;
use Illuminate\Support\Facades\Hash;

class ProviderSeeder extends Seeder
{
  /**
   * Run the database seeds.
   */
  public function run(): void
  {
    // Create sample providers
    $providers = [
      [
        'user' => [
          'name' => 'Tukang Listrik Andi',
          'email' => 'andi.listrik@example.com',
          'phone' => '081234567890',
        ],
        'profile' => [
          'business_name' => 'Andi Jasa Listrik',
          'description' => 'Berpengalaman 10 tahun di bidang listrik',
          'area' => 'Bojongloa Kaler',
          'address' => 'Jl. Merdeka No. 123',
        ],
        'category_ids' => [1],
      ],
      [
        'user' => [
          'name' => 'Tukang Plumbing Budi',
          'email' => 'budi.plumbing@example.com',
          'phone' => '081298765432',
        ],
        'profile' => [
          'business_name' => 'Budi Plumbing Service',
          'description' => 'Ahli sistem perpipaan dan air',
          'area' => 'Bojongloa Kaler',
          'address' => 'Jl. Ahmad Yani No. 456',
        ],
        'category_ids' => [2],
      ],
      [
        'user' => [
          'name' => 'Teknisi AC Citra',
          'email' => 'citra.ac@example.com',
          'phone' => '081345678901',
        ],
        'profile' => [
          'business_name' => 'Citra AC Service',
          'description' => 'Spesialis service AC semua merk',
          'area' => 'Bojongloa Kaler',
          'address' => 'Jl. Sudirman No. 789',
        ],
        'category_ids' => [3],
      ],
    ];

    foreach ($providers as $providerData) {
      $categoryIds = $providerData['category_ids'];
      $userData = $providerData['user'];
      $profileData = $providerData['profile'];

      // Create or update user by unique email
      $user = User::updateOrCreate(
        ['email' => $userData['email']],
        array_merge($userData, [
          'password' => Hash::make('password123'),
          'role' => 'PROVIDER',
          'status' => 'ACTIVE',
        ])
      );

      // Create or update provider profile
      $profile = ProviderProfile::updateOrCreate(
        ['user_id' => $user->id],
        array_merge($profileData, [
          'is_verified' => true,
          'avg_rating' => 0,
        ])
      );

      // Create services without duplicating existing entries
      foreach ($categoryIds as $categoryId) {
        ProviderService::firstOrCreate([
          'provider_profile_id' => $profile->id,
          'category_id' => $categoryId,
          'name' => 'Service Standard',
        ], [
          'base_price' => 150000,
          'price_unit' => 'per kunjungan',
          'is_active' => true,
        ]);
      }
    }
  }
}
