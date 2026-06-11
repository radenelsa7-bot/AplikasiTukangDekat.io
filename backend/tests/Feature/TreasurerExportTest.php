<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TreasurerExportTest extends TestCase
{
  use RefreshDatabase;

  public function test_csv_export_requires_treasurer()
  {
    // create a regular user and a treasurer
    $user = User::factory()->create(['role' => 'CUSTOMER']);
    $treasurer = User::factory()->create(['role' => 'TREASURER']);

    // create related order/payment
    $order = Order::factory()->create();
    $payment = Payment::factory()->create([
      'order_id' => $order->id,
      'status' => 'PAID',
      'amount' => 10000,
    ]);

    // unauthenticated should be forbidden
    $res = $this->getJson('/api/treasurer/payments/report?export=csv');
    $res->assertStatus(401);

    // non-treasurer authenticated should be forbidden
    $res = $this->actingAs($user, 'sanctum')->getJson('/api/treasurer/payments/report?export=csv');
    $res->assertStatus(403);

    // treasurer should get CSV stream
    $res = $this->actingAs($treasurer, 'sanctum')->get('/api/treasurer/payments/report?export=csv');
    $res->assertStatus(200);
    $this->assertStringContainsString('text/csv', $res->headers->get('Content-Type'));
    // log content for debugging in CI logs if needed, using errorlog to avoid file permission issues
    \Illuminate\Support\Facades\Log::channel('errorlog')->debug('treasurer.csv.content', ['content' => $res->getContent()]);
    $this->assertStringContainsString('payment_id', $res->getContent());
    $this->assertStringContainsString((string)$payment->id, $res->getContent());
  }

  public function test_xls_export_requires_treasurer()
  {
    $treasurer = User::factory()->create(['role' => 'TREASURER']);
    $order = Order::factory()->create();
    $payment = Payment::factory()->create([
      'order_id' => $order->id,
      'status' => 'PAID',
      'amount' => 15000,
    ]);

    $res = $this->actingAs($treasurer, 'sanctum')->get('/api/treasurer/payments/report?export=xls');
    $res->assertStatus(200);
    $res->assertHeader('Content-Type');
    $this->assertStringContainsString('treasurer_payments_', $res->headers->get('content-disposition'));
    $this->assertStringContainsString((string)$payment->id, $res->getContent());
  }
}
