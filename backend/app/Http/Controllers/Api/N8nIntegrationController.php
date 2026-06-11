<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\N8nNotificationService;
use Illuminate\Http\Request;

class N8nIntegrationController extends Controller
{
  private const SUPPORTED_EVENTS = [
    'order_created',
    'order_accepted',
    'order_rejected',
    'dp_paid',
    'order_completed',
    'final_paid',
  ];

  public function dispatchEvent(Request $request)
  {
    $validated = $request->validate([
      'event_name' => 'required|string',
      'payload' => 'sometimes|array',
      'channel' => 'sometimes|string|in:WA,EMAIL',
    ]);

    $secretKey = config('services.n8n.event_secret');
    if ($secretKey) {
      $header = $request->header('X-N8N-EVENT-SECRET');
      if (!$header || !hash_equals($secretKey, $header)) {
        return response()->json(['message' => 'invalid event secret'], 403);
      }
    }

    $eventName = $this->normalizeEventName($validated['event_name']);

    if (!in_array($eventName, self::SUPPORTED_EVENTS, true)) {
      return response()->json(['message' => 'unsupported event_name'], 422);
    }

    $log = app(N8nNotificationService::class)->dispatch(
      $eventName,
      $validated['payload'] ?? [],
      $validated['channel'] ?? 'WA',
    );

    return response()->json([
      'message' => 'event_dispatched',
      'data' => [
        'event_name' => $eventName,
        'channel' => $log->channel,
        'status' => $log->status,
        'id' => $log->id,
      ],
    ], 200);
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
