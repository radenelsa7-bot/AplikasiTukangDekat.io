<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class CustomerSeeder extends Seeder
{
  /**
   * Run the database seeds.
   */
  public function run(): void
  {
    $customers = [
      [
        'name' => 'Fajar Hidayatullah',
        'email' => 'fajar@example.com',
        'phone' => '089876543210',
      ],
      [
        'name' => 'Nabila Putri',
        'email' => 'nabila@example.com',
        'phone' => '088765432109',
      ],
      [
        'name' => 'Aldo Pratama',
        'email' => 'aldo@example.com',
        'phone' => '087654321098',
      ],
    ];

    foreach ($customers as $customer) {
      User::updateOrCreate(
        ['email' => $customer['email']],
        array_merge($customer, [
          'password' => Hash::make('password123'),
          'role' => 'CUSTOMER',
          'status' => 'ACTIVE',
        ])
      );
    }
  }
}
