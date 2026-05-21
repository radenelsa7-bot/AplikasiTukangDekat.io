<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;

class AdminSeeder extends Seeder
{
  use WithoutModelEvents;

  /**
   * Run the database seeds.
   */
  public function run(): void
  {
    $email = env('ADMIN_SEED_EMAIL', 'admin@example.com');
    $phone = env('ADMIN_SEED_PHONE', '081234567890');
    $password = env('ADMIN_SEED_PASSWORD', 'password');

    User::updateOrCreate(
      ['email' => $email],
      [
        'name' => 'Administrator',
        'email' => $email,
        'phone' => $phone,
        'password' => $password,
        'role' => 'ADMIN',
        'status' => 'ACTIVE',
      ]
    );
  }
}
