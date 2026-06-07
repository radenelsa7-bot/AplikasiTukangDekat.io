<?php
require 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;

try {
    $user = User::create([
        'name' => 'Test User',
        'email' => 'test@example.com',
        'phone' => '082123456789',
        'password' => Hash::make('password123'),
        'role' => 'CUSTOMER',
        'status' => 'ACTIVE'
    ]);
    echo "✓ User created: {$user->email}\n";
} catch (\Exception $e) {
    echo "Error: {$e->getMessage()}\n";
}
