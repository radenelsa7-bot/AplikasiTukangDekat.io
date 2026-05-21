<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use App\Models\ProviderPayout;
use App\Jobs\SendProviderPayoutJob;

class PayoutRetryTest extends TestCase
{
  use RefreshDatabase;

  #[\PHPUnit\Framework\Attributes\Test]
  public function payout_retries_until_max_attempts_and_then_fails()
  {
    // create minimal user/order/payment as in other test
    $customerId = DB::table('users')->insertGetId([
      'name' => 'Retry Customer',
      'email' => 'retry@example.test',
      'password' => bcrypt('secret'),
      'created_at' => now(),
      'updated_at' => now(),
    ]);
    $providerId = DB::table('users')->insertGetId([
      'name' => 'Retry Provider',
      'email' => 'retryprov@example.test',
      'password' => bcrypt('secret'),
      'created_at' => now(),
      'updated_at' => now(),
    ]);

    $orderId = DB::table('orders')->insertGetId([
      'order_code' => 'RTY-' . strtoupper(bin2hex(random_bytes(3))),
      'customer_id' => $customerId,
      'provider_id' => $providerId,
      'schedule_at' => now(),
      'address' => 'Test',
      'estimated_price' => 50000,
      'created_at' => now(),
      'updated_at' => now(),
    ]);

    DB::table('payments')->insert([
      'order_id' => $orderId,
      'payment_type' => 'FINAL',
      'amount' => 50000,
      'commission_percent' => 0,
      'platform_fee' => 0,
      'provider_payout' => 40000,
      'status' => 'PAID',
      'created_at' => now(),
      'updated_at' => now(),
    ]);

    Artisan::call('payouts:process');
    $payout = ProviderPayout::first();

    $max = (int) config('payout.max_attempts', 3);
    for ($i = 1; $i <= $max; $i++) {
      $job = new SendProviderPayoutJob($payout->id, ['force_fail' => true]);
      try {
        $job->handle();
      } catch (\RuntimeException $e) {
        // expected until max reached
      }

      $payout->refresh();
      $attempts = $payout->attempts()->count();
      $this->assertEquals($i, $attempts);
      if ($i < $max) {
        $this->assertEquals('PENDING', $payout->status);
      }
    }

    // one more attempt should mark as FAILED (max reached)
    $job = new SendProviderPayoutJob($payout->id, ['force_fail' => true]);
    try {
      $job->handle();
    } catch (\RuntimeException $e) {
    }

    $payout->refresh();
    $this->assertEquals('FAILED', $payout->status);
  }
}
