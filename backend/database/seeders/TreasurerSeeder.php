<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class TreasurerSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $email = env('TREASURER_SEED_EMAIL', 'treasurer@example.com');
        $phone = env('TREASURER_SEED_PHONE', '081234567891');
        $password = env('TREASURER_SEED_PASSWORD', 'password');

        User::updateOrCreate(
            ['email' => $email],
            [
                'name' => 'Bendahara',
                'email' => $email,
                'phone' => $phone,
                'password' => Hash::make($password),
                'role' => 'TREASURER',
                'status' => 'ACTIVE',
            ]
        );
    }
}
