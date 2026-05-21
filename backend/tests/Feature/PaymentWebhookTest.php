<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PaymentWebhookTest extends TestCase
{
  use RefreshDatabase;

  public function test_midtrans_webhook_marks_payment_paid_and_closes_final_order(): void
  {
    config([
      'services.payments.driver' => 'midtrans',
      'services.payments.midtrans_server_key' => 'midtrans-secret-key',
      'services.payments.midtrans_is_production' => false,
      'services.payments.platform_commission_percent' => 0,
    ]);

    $customer = User::factory()->create(['role' => 'CUSTOMER']);
    $provider = User::factory()->create(['role' => 'PROVIDER']);

    $order = Order::create([
      'order_code' => 'ORD-' . now()->format('Ymd') . '-0001',
      'customer_id' => $customer->id,
      'provider_id' => $provider->id,
      'schedule_at' => now()->addDay(),
      'address' => 'Jl. Test 123',
      'estimated_price' => 150000,
      'final_price' => 150000,
      'status' => 'CREATED',
    ]);

    $payment = Payment::create([
      'order_id' => $order->id,
      'payment_type' => 'FINAL',
      'amount' => 150000,
      'commission_percent' => 0,
      'platform_fee' => 0,
      'provider_payout' => 0,
      'status' => 'PENDING',
      'provider' => null,
      'external_payment_id' => 'PAY-' . $order->id . '-ABC123',
    ]);

    $payload = [
      'order_id' => $payment->external_payment_id,
      'status_code' => '200',
      'gross_amount' => (string) $payment->amount,
      'transaction_status' => 'settlement',
      'transaction_id' => 'TX-' . time(),
      'signature_key' => hash('sha512', $payment->external_payment_id . '200' . $payment->amount . 'midtrans-secret-key'),
      'metadata' => [
        'payment_id' => $payment->id,
      ],
    ];

    $response = $this->postJson('/api/webhooks/payment', $payload);

    $response->assertStatus(200)->assertJson(['message' => 'payment processed']);

    $payment->refresh();
    $order->refresh();

    $this->assertSame('PAID', $payment->status);
    $this->assertSame('MIDTRANS', $payment->provider);
    $this->assertNotNull($payment->paid_at);
    $this->assertSame('READY', $payment->settlement_status);
    $this->assertSame(150000, (int) $payment->provider_payout);
    $this->assertSame('CLOSED', $order->status);
  }

  public function test_midtrans_webhook_rejects_invalid_signature(): void
  {
    config([
      'services.payments.driver' => 'midtrans',
      'services.payments.midtrans_server_key' => 'midtrans-secret-key',
    ]);

    $customer = User::factory()->create(['role' => 'CUSTOMER']);
    $provider = User::factory()->create(['role' => 'PROVIDER']);

    $order = Order::create([
      'order_code' => 'ORD-' . now()->format('Ymd') . '-0002',
      'customer_id' => $customer->id,
      'provider_id' => $provider->id,
      'schedule_at' => now()->addDay(),
      'address' => 'Jl. Test 456',
      'estimated_price' => 50000,
      'final_price' => 50000,
      'status' => 'CREATED',
    ]);

    $payment = Payment::create([
      'order_id' => $order->id,
      'payment_type' => 'DP',
      'amount' => 50000,
      'commission_percent' => 0,
      'platform_fee' => 0,
      'provider_payout' => 0,
      'status' => 'PENDING',
      'provider' => null,
      'external_payment_id' => 'PAY-' . $order->id . '-XYZ789',
    ]);

    $response = $this->postJson('/api/webhooks/payment', [
      'order_id' => $payment->external_payment_id,
      'status_code' => '200',
      'gross_amount' => (string) $payment->amount,
      'transaction_status' => 'settlement',
      'signature_key' => 'invalid-signature',
      'metadata' => ['payment_id' => $payment->id],
    ]);

    $response->assertStatus(403)->assertJson(['message' => 'invalid signature']);

    $payment->refresh();
    $order->refresh();

    $this->assertSame('PENDING', $payment->status);
    $this->assertSame('CREATED', $order->status);
  }
}
