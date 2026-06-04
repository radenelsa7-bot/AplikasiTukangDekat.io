<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use App\Models\Payment;
use App\Models\NotificationLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

class N8nIntegrationTest extends TestCase
{
  use RefreshDatabase;

  private User $customer;
  private User $provider;

  protected function setUp(): void
  {
    parent::setUp();

    // Create test users
    $this->customer = User::factory()->create(['role' => 'CUSTOMER']);
    $this->provider = User::factory()->create(['role' => 'PROVIDER']);
  }

  /**
   * Test health check endpoint
   */
  public function test_health_check_endpoint(): void
  {
    $response = $this->getJson('/api/integrations/health');

    $response->assertStatus(200)
      ->assertJsonStructure([
        'status',
        'timestamp',
        'service',
      ]);
  }

  /**
   * Test order created event dispatch
   */
  public function test_order_created_event_dispatch(): void
  {
    Http::fake();

    $this->actingAs($this->customer, 'sanctum');

    $response = $this->postJson('/api/orders', [
      'provider_id' => $this->provider->id,
      'category_id' => 1,
      'schedule_at' => now()->addDays(1)->format('Y-m-d H:i:s'),
      'address' => 'Jl. Test',
      'estimated_price' => 100000,
    ]);

    $response->assertStatus(201);

    // Verify notification log was created
    $this->assertDatabaseHas('notification_logs', [
      'event_name' => 'order_created',
      'channel' => 'WA',
      'status' => 'SENT',
    ]);
  }

  /**
   * Test order accepted event dispatch
   */
  public function test_order_accepted_event_dispatch(): void
  {
    Http::fake();

    // Create order
    $order = Order::factory()->create([
      'customer_id' => $this->customer->id,
      'provider_id' => $this->provider->id,
      'status' => 'CREATED',
    ]);

    $this->actingAs($this->provider, 'sanctum');

    $response = $this->postJson("/api/orders/{$order->id}/respond", [
      'action' => 'accept',
    ]);

    $response->assertStatus(200);

    // Verify notification log
    $this->assertDatabaseHas('notification_logs', [
      'event_name' => 'order_accepted',
      'channel' => 'WA',
      'status' => 'SENT',
    ]);
  }

  /**
   * Test order rejected event dispatch
   */
  public function test_order_rejected_event_dispatch(): void
  {
    Http::fake();

    $order = Order::factory()->create([
      'customer_id' => $this->customer->id,
      'provider_id' => $this->provider->id,
      'status' => 'CREATED',
    ]);

    $this->actingAs($this->provider, 'sanctum');

    $response = $this->postJson("/api/orders/{$order->id}/respond", [
      'action' => 'reject',
    ]);

    $response->assertStatus(200);

    // Verify notification log
    $this->assertDatabaseHas('notification_logs', [
      'event_name' => 'order_rejected',
      'channel' => 'WA',
      'status' => 'SENT',
    ]);
  }

  /**
   * Test order completed event dispatch
   */
  public function test_order_completed_event_dispatch(): void
  {
    Http::fake();

    $order = Order::factory()->create([
      'customer_id' => $this->customer->id,
      'provider_id' => $this->provider->id,
      'status' => 'IN_PROGRESS',
    ]);

    $this->actingAs($this->provider, 'sanctum');

    $response = $this->postJson("/api/orders/{$order->id}/complete", [
      'final_price' => 100000,
    ]);

    $response->assertStatus(200);

    // Verify notification log
    $this->assertDatabaseHas('notification_logs', [
      'event_name' => 'order_completed',
      'channel' => 'WA',
      'status' => 'SENT',
    ]);
  }

  /**
   * Test payment dp paid event dispatch
   */
  public function test_payment_dp_paid_event_dispatch(): void
  {
    Http::fake();

    $order = Order::factory()->create([
      'customer_id' => $this->customer->id,
      'provider_id' => $this->provider->id,
    ]);

    $payment = Payment::factory()->create([
      'order_id' => $order->id,
      'payment_type' => 'DP',
      'status' => 'UNPAID',
    ]);

    $response = $this->postJson('/api/webhooks/payment', [
      'payment_id' => $payment->id,
      'status' => 'PAID',
      'transaction_id' => 'TXN123',
    ]);

    // Verify notification log for dp_paid
    $this->assertDatabaseHas('notification_logs', [
      'event_name' => 'payment_dp_paid',
      'channel' => 'WA',
      'status' => 'SENT',
    ]);
  }

  /**
   * Test get notification logs
   */
  public function test_get_notification_logs(): void
  {
    // Create test logs
    NotificationLog::create([
      'event_name' => 'order_created',
      'channel' => 'WA',
      'payload_json' => '{}',
      'status' => 'SENT',
      'sent_at' => now(),
    ]);

    NotificationLog::create([
      'event_name' => 'order_accepted',
      'channel' => 'EMAIL',
      'payload_json' => '{}',
      'status' => 'FAILED',
      'sent_at' => null,
    ]);

    $this->actingAs($this->customer, 'sanctum');

    $response = $this->getJson('/api/integrations/notifications/logs');

    $response->assertStatus(200)
      ->assertJsonStructure([
        'data' => [
          '*' => [
            'id',
            'event_name',
            'channel',
            'payload_json',
            'status',
            'sent_at',
          ],
        ],
        'pagination',
      ]);
  }

  /**
   * Test get notification logs with filters
   */
  public function test_get_notification_logs_with_filters(): void
  {
    NotificationLog::create([
      'event_name' => 'order_created',
      'channel' => 'WA',
      'payload_json' => '{}',
      'status' => 'SENT',
      'sent_at' => now(),
    ]);

    NotificationLog::create([
      'event_name' => 'order_created',
      'channel' => 'EMAIL',
      'payload_json' => '{}',
      'status' => 'SENT',
      'sent_at' => now(),
    ]);

    $this->actingAs($this->customer, 'sanctum');

    $response = $this->getJson('/api/integrations/notifications/logs?event_name=order_created&channel=WA');

    $response->assertStatus(200)
      ->assertJsonCount(1, 'data');
  }

  /**
   * Test get notification log detail
   */
  public function test_get_notification_log_detail(): void
  {
    $log = NotificationLog::create([
      'event_name' => 'order_created',
      'channel' => 'WA',
      'payload_json' => json_encode(['order_id' => 1]),
      'status' => 'SENT',
      'sent_at' => now(),
    ]);

    $this->actingAs($this->customer, 'sanctum');

    $response = $this->getJson("/api/integrations/notifications/logs/{$log->id}");

    $response->assertStatus(200)
      ->assertJsonStructure([
        'data' => [
          'id',
          'event_name',
          'channel',
          'payload',
          'status',
          'sent_at',
          'created_at',
        ],
      ]);
  }

  /**
   * Test handle n8n event endpoint
   */
  public function test_handle_n8n_event_endpoint(): void
  {
    Http::fake();

    $this->actingAs($this->customer, 'sanctum');

    $response = $this->postJson('/api/integrations/n8n/events', [
      'event_name' => 'order_created',
      'data' => [
        'order_id' => 1,
        'customer_id' => $this->customer->id,
      ],
      'channel' => 'WA',
    ]);

    $response->assertStatus(200)
      ->assertJsonStructure([
        'message',
        'status',
      ]);

    // Verify log was created
    $this->assertDatabaseHas('notification_logs', [
      'event_name' => 'order_created',
      'channel' => 'WA',
    ]);
  }

  /**
   * Test handle n8n event with invalid data
   */
  public function test_handle_n8n_event_invalid_event_name(): void
  {
    $this->actingAs($this->customer, 'sanctum');

    $response = $this->postJson('/api/integrations/n8n/events', [
      'event_name' => 'invalid_event',
      'data' => [],
      'channel' => 'WA',
    ]);

    $response->assertStatus(422);
  }

  /**
   * Test n8n webhook callback
   */
  public function test_n8n_webhook_callback(): void
  {
    $response = $this->postJson('/api/integrations/n8n/webhook', [
      'message_id' => 'MSG123',
      'status' => 'delivered',
      'phone' => '628123456789',
    ]);

    $response->assertStatus(200)
      ->assertJsonStructure([
        'message',
        'received_at',
      ]);
  }

  /**
   * Test notification logs are created on payment webhook
   */
  public function test_notification_logs_created_on_payment_webhook(): void
  {
    Http::fake();

    $order = Order::factory()->create([
      'customer_id' => $this->customer->id,
      'provider_id' => $this->provider->id,
    ]);

    $payment = Payment::factory()->create([
      'order_id' => $order->id,
      'payment_type' => 'DP',
      'status' => 'UNPAID',
    ]);

    $response = $this->postJson('/api/webhooks/payment', [
      'payment_id' => $payment->id,
      'status' => 'PAID',
      'transaction_id' => 'TXN123',
    ]);

    $response->assertStatus(200);

    // Verify notification logs were created
    $this->assertDatabaseHas('notification_logs', [
      'event_name' => 'payment_dp_paid',
    ]);
  }

  /**
   * Test unauthenticated access to protected endpoints
   */
  public function test_unauthenticated_access_to_protected_endpoints(): void
  {
    $response = $this->getJson('/api/integrations/notifications/logs');
    $response->assertStatus(401);

    $response = $this->postJson('/api/integrations/n8n/events', [
      'event_name' => 'order_created',
      'data' => [],
      'channel' => 'WA',
    ]);
    $response->assertStatus(401);
  }

  /**
   * Test health check is public
   */
  public function test_health_check_is_public(): void
  {
    $response = $this->getJson('/api/integrations/health');
    $response->assertStatus(200);
  }
}
