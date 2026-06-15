<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class N8nIntegrationTest extends TestCase
{
  use RefreshDatabase;

  public function test_can_dispatch_n8n_event_with_secret(): void
  {
    config([
      'services.n8n.webhook_url' => 'http://localhost:5678/webhook/n8n-events',
      'services.n8n.secret' => 'n8n-webhook-secret',
      'services.n8n.event_secret' => 'n8n-event-secret',
    ]);

    Http::fake();

    $response = $this->postJson('/api/integrations/n8n/events', [
      'event_name' => 'order_created',
      'payload' => ['order_id' => 123, 'customer_id' => 1],
      'channel' => 'WA',
    ], [
      'X-N8N-EVENT-SECRET' => 'n8n-event-secret',
    ]);

    $response->assertStatus(200)->assertJson(['message' => 'event_dispatched']);

    $response->assertJsonPath('data.event_name', 'order_created');
  }

  public function test_event_dispatch_requires_valid_secret_when_configured(): void
  {
    config([
      'services.n8n.event_secret' => 'n8n-event-secret',
    ]);

    $response = $this->postJson('/api/integrations/n8n/events', [
      'event_name' => 'order_created',
      'payload' => ['order_id' => 123],
    ], [
      'X-N8N-EVENT-SECRET' => 'invalid-secret',
    ]);

    $response->assertStatus(403)->assertJson(['message' => 'invalid event secret']);
  }
}
