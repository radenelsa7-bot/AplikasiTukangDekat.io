<?php

namespace App\Services;

use App\Models\NotificationLog;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class N8nNotificationService
{
  private string $webhookUrl;
  private string $secret;
  private string $n8nUrl;

  public function __construct()
  {
    $this->webhookUrl = config('services.n8n.webhook_url', '');
    $this->secret = config('services.n8n.secret', '');
    $this->n8nUrl = config('services.n8n.url', 'http://localhost:5678');
  }

  /**
   * Dispatch event ke n8n notification service
   */
  public function dispatch(string $eventName, array $payload, string $channel = 'WA'): NotificationLog
  {
    $log = NotificationLog::create([
      'event_name' => $eventName,
      'channel' => $channel,
      'payload_json' => json_encode($payload),
      'status' => 'SENT',
      'sent_at' => null,
    ]);

    if (!$this->webhookUrl) {
      Log::warning('N8n webhook URL not configured', ['event' => $eventName]);
      $log->update(['status' => 'FAILED']);
      return $log;
    }

    try {
      $request = Http::timeout(30)->acceptJson();

      if ($this->secret) {
        $request = $request->withHeaders([
          'X-N8N-SECRET' => $this->secret,
          'X-N8N-Event' => $eventName,
        ]);
      }

      $response = $request->post($this->webhookUrl, [
        'event_name' => $eventName,
        'channel' => $channel,
        'payload' => $payload,
        'sent_at' => now()->toIso8601String(),
      ]);

      $status = $response->successful() ? 'SENT' : 'FAILED';
      
      $log->update([
        'status' => $status,
        'sent_at' => $response->successful() ? now() : null,
      ]);

      if ($response->successful()) {
        Log::info('Notification dispatched to n8n', [
          'event' => $eventName,
          'channel' => $channel,
        ]);
      } else {
        Log::warning('N8n webhook returned error', [
          'event' => $eventName,
          'status' => $response->status(),
        ]);
      }
    } catch (\Throwable $e) {
      $log->update([
        'status' => 'FAILED',
        'sent_at' => null,
      ]);

      Log::error('N8n dispatch failed', [
        'event' => $eventName,
        'error' => $e->getMessage(),
      ]);
    }

    return $log;
  }

  /**
   * Dispatch event untuk order lifecycle
   */
  public function dispatchOrderEvent(string $eventName, $order, string $channel = 'WA'): NotificationLog
  {
    $payload = $this->buildOrderPayload($eventName, $order);
    return $this->dispatch($eventName, $payload, $channel);
  }

  /**
   * Dispatch event untuk payment
   */
  public function dispatchPaymentEvent(string $eventName, $payment, string $channel = 'WA'): NotificationLog
  {
    $payload = $this->buildPaymentPayload($eventName, $payment);
    return $this->dispatch($eventName, $payload, $channel);
  }

  /**
   * Build order payload
   */
  private function buildOrderPayload(string $eventName, $order): array
  {
    return [
      'order_id' => $order->id,
      'customer_id' => $order->customer_id,
      'provider_id' => $order->provider_id,
      'service_id' => $order->service_id,
      'customer_name' => $order->customer->name ?? 'Customer',
      'customer_phone' => $order->customer->phone ?? '',
      'provider_name' => $order->provider->user->name ?? 'Provider',
      'provider_phone' => $order->provider->user->phone ?? '',
      'service_name' => $order->service->name ?? 'Service',
      'status' => $order->status,
      'total_price' => $order->total_price,
      'dp_amount' => $order->dp_amount,
      'event_type' => $eventName,
      'timestamp' => now()->toIso8601String(),
    ];
  }

  /**
   * Build payment payload
   */
  private function buildPaymentPayload(string $eventName, $payment): array
  {
    return [
      'payment_id' => $payment->id,
      'order_id' => $payment->order_id,
      'amount' => $payment->amount,
      'status' => $payment->status,
      'method' => $payment->method,
      'provider' => $payment->provider,
      'paid_at' => $payment->paid_at,
      'event_type' => $eventName,
      'timestamp' => now()->toIso8601String(),
    ];
  }

  /**
   * Get n8n health status
   */
  public function getHealthStatus(): array
  {
    try {
      $response = Http::timeout(10)->get("{$this->n8nUrl}/api/health");

      if ($response->successful()) {
        return [
          'healthy' => true,
          'status' => $response->json('status'),
        ];
      }
      return ['healthy' => false];
    } catch (\Exception $e) {
      Log::error('N8n health check failed', ['error' => $e->getMessage()]);
      return ['healthy' => false, 'error' => $e->getMessage()];
    }
  }
}
