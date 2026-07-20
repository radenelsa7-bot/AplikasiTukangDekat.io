<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use App\Services\PaymentGatewayService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MidtransPaymentTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test Midtrans configuration is available
     */
    public function test_midtrans_configuration_available(): void
    {
        $serverKey = config('services.payments.midtrans_server_key');
        $clientKey = config('services.payments.midtrans_client_key');
        $isProduction = config('services.payments.midtrans_is_production');

        $this->assertNotNull($serverKey, 'Midtrans server key should be configured');
        $this->assertNotNull($clientKey, 'Midtrans client key should be configured');
        $this->assertFalse($isProduction, 'Midtrans should be in sandbox mode for testing');
    }

    /**
     * Test Midtrans payload generation for simulation mode
     */
    public function test_midtrans_simulation_payload(): void
    {
        config([
            'services.payments.driver' => 'simulation',
        ]);

        $customer = User::factory()->create(['role' => 'CUSTOMER']);
        $provider = User::factory()->create(['role' => 'PROVIDER']);

        $order = Order::create([
            'order_code' => 'ORD-' . now()->format('Ymd') . '-001',
            'customer_id' => $customer->id,
            'provider_id' => $provider->id,
            'schedule_at' => now()->addDay(),
            'address' => 'Test Address',
            'estimated_price' => 100000,
            'status' => 'CREATED',
        ]);

        $payment = Payment::create([
            'order_id' => $order->id,
            'payment_type' => 'DP',
            'amount' => 50000,
            'commission_percent' => 10,
            'platform_fee' => 5000,
            'provider_payout' => 45000,
            'status' => 'PENDING',
        ]);

        $service = new PaymentGatewayService();
        $payload = $service->generateQrisPayload($payment);

        $this->assertEquals('SIMULATION', $payload['provider'],
            'Simulation provider should be used when driver is simulation');
        $this->assertNotNull($payload['reference'],
            'Reference should be generated');
        $this->assertEquals(50000, $payload['amount'],
            'Amount should match payment amount');
    }

    /**
     * Test Midtrans driver method returns correct value
     */
    public function test_midtrans_driver_method(): void
    {
        config(['services.payments.driver' => 'midtrans']);
        
        $service = new PaymentGatewayService();
        $this->assertEquals('midtrans', $service->driver(),
            'Driver method should return midtrans when configured');
    }

    /**
     * Test Midtrans webhook signature verification
     */
    public function test_midtrans_webhook_signature_verification(): void
    {
        config([
            'services.payments.driver' => 'midtrans',
            'services.payments.midtrans_server_key' => 'test-server-key',
        ]);

        $service = new PaymentGatewayService();
        
        $validPayload = [
            'order_id' => 'TEST-ORDER-123',
            'status_code' => '200',
            'gross_amount' => '50000',
            'transaction_status' => 'settlement',
            'signature_key' => hash('sha512', 'TEST-ORDER-123' . '200' . '50000' . 'test-server-key'),
        ];

        $request = \Illuminate\Http\Request::create(
            '/api/webhooks/payment',
            'POST',
            $validPayload
        );

        $this->assertTrue($service->verifyWebhook($request),
            'Valid Midtrans signature should be verified');
    }

    /**
     * Test Midtrans webhook rejects invalid signature
     */
    public function test_midtrans_webhook_rejects_invalid_signature(): void
    {
        config([
            'services.payments.driver' => 'midtrans',
            'services.payments.midtrans_server_key' => 'test-server-key',
        ]);

        $service = new PaymentGatewayService();
        
        $invalidPayload = [
            'order_id' => 'TEST-ORDER-123',
            'status_code' => '200',
            'gross_amount' => '50000',
            'transaction_status' => 'settlement',
            'signature_key' => 'invalid-signature',
        ];

        $request = \Illuminate\Http\Request::create(
            '/api/webhooks/payment',
            'POST',
            $invalidPayload
        );

        $this->assertFalse($service->verifyWebhook($request),
            'Invalid Midtrans signature should be rejected');
    }

    /**
     * Test Midtrans status mapping
     */
    public function test_midtrans_status_mapping(): void
    {
        config(['services.payments.driver' => 'midtrans']);
        
        $service = new PaymentGatewayService();
        
        $this->assertEquals('PAID', $service->mapStatus('settlement'),
            'Midtrans settlement should map to PAID');
        $this->assertEquals('PAID', $service->mapStatus('capture'),
            'Midtrans capture should map to PAID');
        $this->assertEquals('PENDING', $service->mapStatus('pending'),
            'Midtrans pending should map to PENDING');
        $this->assertEquals('FAILED', $service->mapStatus('expire'),
            'Midtrans expire should map to FAILED');
        $this->assertEquals('FAILED', $service->mapStatus('deny'),
            'Midtrans deny should map to FAILED');
    }

    /**
     * Test payment reference generation
     */
    public function test_payment_reference_generation(): void
    {
        $customer = User::factory()->create(['role' => 'CUSTOMER']);
        $provider = User::factory()->create(['role' => 'PROVIDER']);

        $order = Order::create([
            'order_code' => 'ORD-TESTREF',
            'customer_id' => $customer->id,
            'provider_id' => $provider->id,
            'schedule_at' => now()->addDay(),
            'address' => 'Test Address',
            'estimated_price' => 100000,
            'status' => 'CREATED',
        ]);

        $payment = Payment::create([
            'order_id' => $order->id,
            'payment_type' => 'DP',
            'amount' => 50000,
            'status' => 'PENDING',
        ]);

        $service = new PaymentGatewayService();
        $reference = $service->paymentReference($payment);

        $this->assertStringStartsWith('PAY-' . $payment->id . '-', $reference,
            'Payment reference should follow naming convention');
    }
}