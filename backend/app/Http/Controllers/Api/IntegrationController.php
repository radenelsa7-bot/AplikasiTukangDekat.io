<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\N8nNotificationService;
use App\Models\NotificationLog;
use Illuminate\Http\Request;

class IntegrationController extends Controller
{
  public function __construct(
    private readonly N8nNotificationService $n8nNotificationService,
  ) {}

  /**
   * Handle n8n event webhook
   * Endpoint: POST /api/integrations/n8n/events
   */
  public function handleN8nEvent(Request $request)
  {
    $validated = $request->validate([
      'event_name' => 'required|string|in:order_created,order_accepted,order_rejected,dp_paid,order_completed,final_paid,payment_failed,payout_completed',
      'data' => 'required|array',
      'channel' => 'required|string|in:WA,EMAIL,SMS',
    ]);

    try {
      // Dispatch event ke n8n
      $result = $this->n8nNotificationService->dispatchEvent(
        $validated['event_name'],
        $validated['data'],
        $validated['channel']
      );

      // Log notification
      NotificationLog::create([
        'event_name' => $validated['event_name'],
        'channel' => $validated['channel'],
        'payload_json' => json_encode($validated['data']),
        'status' => $result['success'] ? 'SENT' : 'FAILED',
        'sent_at' => now(),
      ]);

      return response()->json([
        'message' => 'Event dispatched successfully',
        'event_id' => $result['event_id'] ?? null,
        'status' => $result['success'] ? 'sent' : 'failed',
      ], $result['success'] ? 200 : 400);
    } catch (\Exception $e) {
      // Log failure
      NotificationLog::create([
        'event_name' => $validated['event_name'],
        'channel' => $validated['channel'],
        'payload_json' => json_encode($validated['data']),
        'status' => 'FAILED',
        'sent_at' => now(),
      ]);

      \Log::error('N8n event dispatch failed', [
        'event' => $validated['event_name'],
        'error' => $e->getMessage(),
      ]);

      return response()->json([
        'message' => 'Failed to dispatch event',
        'error' => $e->getMessage(),
      ], 500);
    }
  }

  /**
   * Get notification logs
   * Endpoint: GET /api/integrations/notifications/logs
   */
  public function getNotificationLogs(Request $request)
  {
    $query = NotificationLog::query();

    // Filter by event name
    if ($request->has('event_name')) {
      $query->where('event_name', $request->event_name);
    }

    // Filter by channel
    if ($request->has('channel')) {
      $query->where('channel', $request->channel);
    }

    // Filter by status
    if ($request->has('status')) {
      $query->where('status', $request->status);
    }

    // Filter by date range
    if ($request->has('from_date')) {
      $query->whereDate('created_at', '>=', $request->from_date);
    }

    if ($request->has('to_date')) {
      $query->whereDate('created_at', '<=', $request->to_date);
    }

    $logs = $query->orderBy('created_at', 'desc')->paginate(50);

    return response()->json([
      'data' => $logs->items(),
      'pagination' => [
        'total' => $logs->total(),
        'per_page' => $logs->perPage(),
        'current_page' => $logs->currentPage(),
        'last_page' => $logs->lastPage(),
      ],
    ], 200);
  }

  /**
   * Get notification log detail
   * Endpoint: GET /api/integrations/notifications/logs/{id}
   */
  public function getNotificationLogDetail($id)
  {
    $log = NotificationLog::find($id);

    if (!$log) {
      return response()->json(['message' => 'Log not found'], 404);
    }

    return response()->json([
      'data' => [
        'id' => $log->id,
        'event_name' => $log->event_name,
        'channel' => $log->channel,
        'payload' => json_decode($log->payload_json, true),
        'status' => $log->status,
        'sent_at' => $log->sent_at,
        'created_at' => $log->created_at,
      ],
    ], 200);
  }

  /**
   * Health check endpoint untuk n8n
   * Endpoint: GET /api/integrations/health
   */
  public function healthCheck()
  {
    return response()->json([
      'status' => 'healthy',
      'timestamp' => now(),
      'service' => 'n8n-integration',
    ], 200);
  }

  /**
   * N8n webhook callback untuk testing/verification
   * Endpoint: POST /api/integrations/n8n/webhook
   */
  public function n8nWebhookCallback(Request $request)
  {
    // Verify webhook signature dari n8n
    $signature = $request->header('X-N8N-Signature');
    $webhookKey = config('services.n8n.webhook_key');

    if ($signature && $webhookKey) {
      $expectedSignature = hash_hmac('sha256', $request->getContent(), $webhookKey);
      if (!hash_equals($signature, $expectedSignature)) {
        return response()->json(['message' => 'Invalid signature'], 403);
      }
    }

    $data = $request->all();

    // Log callback
    \Log::info('N8n webhook callback received', $data);

    // Process callback (e.g., update status, trigger next action)
    // Ini bisa digunakan untuk tracking status pengiriman WA

    return response()->json([
      'message' => 'Webhook received',
      'received_at' => now(),
    ], 200);
  }
}
