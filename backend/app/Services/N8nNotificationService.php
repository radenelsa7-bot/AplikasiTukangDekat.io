<?php

namespace App\Services;

use App\Models\NotificationLog;
use Illuminate\Support\Facades\Http;

class N8nNotificationService
{
  public function dispatch(string $eventName, array $payload, string $channel = 'WA'): NotificationLog
  {
    $eventName = $this->normalizeEventName($eventName);
    $webhookUrl = config('services.n8n.webhook_url');
    $secret = config('services.n8n.secret');

    $log = NotificationLog::create([
      'event_name' => $eventName,
      'channel' => $channel,
      'payload_json' => json_encode($payload),
      'status' => 'SENT',
      'sent_at' => null,
    ]);

    if (!$webhookUrl) {
      return $log;
    }

    try {
      $request = Http::timeout(10)->acceptJson();

      if ($secret) {
        $request = $request->withHeaders([
          'X-N8N-SECRET' => $secret,
        ]);
      }

      $response = $request->post($webhookUrl, [
        'event_name' => $eventName,
        'channel' => $channel,
        'payload' => $payload,
        'sent_at' => now()->toIso8601String(),
      ]);

      $log->update([
        'status' => $response->successful() ? 'SENT' : 'FAILED',
        'sent_at' => $response->successful() ? now() : null,
      ]);
    } catch (\Throwable $e) {
      $log->update([
        'status' => 'FAILED',
        'sent_at' => null,
      ]);
    }

    return $log;
  }

  private function normalizeEventName(string $eventName): string
  {
    $aliases = [
      'payment_dp_paid' => 'dp_paid',
      'payment_final_paid' => 'final_paid',
    ];

    return $aliases[$eventName] ?? $eventName;
  }
}
