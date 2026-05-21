<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class CreateTestToken extends Command
{
  protected $signature = 'test:make-token {email=test.treasurer@example.com} {--save : Save token to e2e/.env}';
  protected $description = 'Create or find a TREASURER user and emit a personal access TEST_TOKEN (Sanctum)';

  public function handle()
  {
    $email = $this->argument('email');

    $user = User::query()->where('email', $email)->first();
    if (!$user) {
      $this->info('User not found, creating new TREASURER user...');
      $user = User::create([
        'name' => 'E2E Treasurer',
        'email' => $email,
        'password' => Hash::make('password'),
        'role' => 'TREASURER',
        'status' => 'active',
      ]);
    } else {
      $this->info('Found existing user, ensuring role/status...');
      $user->role = 'TREASURER';
      $user->status = 'active';
      $user->save();
    }

    // revoke previous e2e tokens for clarity
    foreach ($user->tokens as $t) {
      if (Str::contains((string) $t->name, 'e2e')) {
        $t->delete();
      }
    }

    $token = $user->createToken('e2e-token')->plainTextToken;

    $this->info('TEST_TOKEN: ' . $token);

    if ($this->option('save')) {
      $path = base_path('e2e/.env');
      $content = "TEST_TOKEN={$token}\n";
      @file_put_contents($path, $content);
      $this->info('Saved TEST_TOKEN to ' . $path);
    }

    return 0;
  }
}
