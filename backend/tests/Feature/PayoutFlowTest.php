<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\DB;
use App\Models\Payment;
use App\Models\ProviderPayout;
use App\Jobs\SendProviderPayoutJob;

class PayoutFlowTest extends TestCase
{
  use RefreshDatabase;

  #[\PHPUnit\Framework\Attributes\Test]
  public function aggregation_command_runs()
  {
    // create sample paid payment row directly to avoid missing factories
    // Temporarily disable foreign key checks for in-memory sqlite
    // create minimal users and order so foreign keys are satisfied
    $customerId = DB::table('users')->insertGetId([
      'name' => 'Test Customer',
      'email' => 'customer@example.test',
      'password' => bcrypt('secret'),
      'created_at' => now(),
      'updated_at' => now(),
    ]);
    $providerId = DB::table('users')->insertGetId([
      'name' => 'Test Provider',
      'email' => 'provider@example.test',
      'password' => bcrypt('secret'),
      'created_at' => now(),
      'updated_at' => now(),
    ]);

    $orderId = DB::table('orders')->insertGetId([
      'order_code' => 'TST-' . strtoupper(bin2hex(random_bytes(3))),
      'customer_id' => $customerId,
      'provider_id' => $providerId,
      'schedule_at' => now(),
      'address' => 'Test address',
      'estimated_price' => 100000,
      'created_at' => now(),
      'updated_at' => now(),
    ]);

    DB::table('payments')->insert([
      'order_id' => $orderId,
      'payment_type' => 'FINAL',
      'amount' => 100000,
      'commission_percent' => 0,
      'platform_fee' => 0,
      'provider_payout' => 10000,
      'status' => 'PAID',
      'created_at' => now(),
      'updated_at' => now(),
    ]);

    Artisan::call('payouts:process');

    $this->assertDatabaseCount('provider_payouts', 1);

    // ensure pending process dispatches jobs
    Bus::fake();
    Artisan::call('payouts:process-pending', ['--limit' => 10]);
    Bus::assertDispatched(SendProviderPayoutJob::class);

    // run job synchronously (queue connection sync during test)
    config(['queue.default' => 'sync']);
    $payout = ProviderPayout::first();
    $job = new SendProviderPayoutJob($payout->id, ['force_fail' => true]);
    try {
      $job->handle();
      $this->fail('Expected runtime exception from failed gateway');
    } catch (\RuntimeException $e) {
      $this->assertStringContainsString('Gateway send failed', $e->getMessage());
    }

    $this->assertDatabaseHas('provider_payout_attempts', ['provider_payout_id' => $payout->id, 'status' => 'FAILED']);
  }
}
