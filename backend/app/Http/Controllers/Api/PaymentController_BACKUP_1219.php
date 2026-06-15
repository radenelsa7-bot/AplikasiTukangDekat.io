<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Payment;
use App\Services\PaymentGatewayService;
use App\Services\PaymentFinanceService;
use App\Services\N8nNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class PaymentController extends Controller
{
  public function __construct(
    private readonly PaymentGatewayService $paymentGatewayService,
    private readonly PaymentFinanceService $paymentFinanceService,
  ) {}

  /**
   * Get payment untuk order
   */
  public function getPayments($orderId)
  {
    $user = Auth::user();
    $order = Order::with(['customer', 'provider'])->find($orderId);

    if (!$order) {
      return response()->json(['message' => 'order not found'], 404);
    }

    if ($user->role !== 'ADMIN' && $user->role !== 'TREASURER' && $order->customer_id !== $user->id && $order->provider_id !== $user->id) {
      return response()->json(['message' => 'unauthorized'], 403);
    }

    $payments = Payment::where('order_id', $orderId)->get();

    return $this->successResponse(['payments' => $payments], 'ok', 200);
  }

  /**
   * Generate QRIS untuk payment
   */
  public function generateQRIS(Request $request, $paymentId)
  {
    $payment = Payment::with(['order.customer', 'order.provider'])->find($paymentId);

    if (!$payment) {
      return $this->notFoundResponse('payment not found');
    }

    if ($response = $this->authorizePaymentAccess($payment, false)) {
      return $response;
    }

    $qrisData = $this->paymentGatewayService->generateQrisPayload($payment);

    $payment->update([
      'provider' => $qrisData['provider'] ?? $payment->provider,
      'external_payment_id' => $qrisData['reference'] ?? $payment->external_payment_id,
      'qris_code' => $qrisData['qris_code'] ?? $payment->qris_code,
      'qris_image' => $qrisData['qris_image'] ?? $payment->qris_image,
      'checkout_url' => $qrisData['checkout_url'] ?? $payment->checkout_url,
      'status' => $payment->status === 'UNPAID' ? 'PENDING' : $payment->status,
      'qris_code' => $qrisData['qris_code'] ?? $payment->qris_code,
      'qris_image' => $qrisData['qris_image'] ?? $payment->qris_image,
      'checkout_url' => $qrisData['checkout_url'] ?? $payment->checkout_url,
    ]);

    return $this->successResponse(['qris' => $qrisData], 'ok', 200);
  }

  /**
   * Webhook callback dari payment gateway
   * Endpoint ini menerima notifikasi pembayaran dari Midtrans/Xendit
   */
  public function webhookPaymentCallback(Request $request)
  {
    if (!$this->paymentGatewayService->verifyWebhook($request)) {
      return $this->forbiddenResponse('invalid signature');
    }

    $data = $request->all();

    $paymentId = $data['payment_id'] ?? data_get($data, 'metadata.payment_id');
    $externalPaymentId = $data['transaction_id'] ?? $data['reference'] ?? $data['order_id'] ?? $data['external_payment_id'] ?? null;
    $status = $data['status'] ?? $data['transaction_status'] ?? $data['payment_status'] ?? null;

    if (!$paymentId && !$externalPaymentId) {
      return $this->errorResponse('invalid payload', 400);
    }

    $payment = Payment::when($paymentId, function ($query) use ($paymentId) {
      $query->where('id', $paymentId);
    }, function ($query) use ($externalPaymentId) {
      $query->where('external_payment_id', $externalPaymentId);
    })->first();

    if (!$payment) {
      return $this->notFoundResponse('payment not found');
    }

    // Idempotency: compute a stable event hash and record it before processing.
    $driver = $this->paymentGatewayService->driver();
    $sigHeader = (string) $request->header(config('services.payments.webhook_signature_header', 'X-Payment-Signature'), '');
    $rawSignature = $sigHeader !== '' ? $sigHeader : (string) ($request->input('signature_key') ?? '');
    $extIdForHash = $externalPaymentId ?? ($paymentId ?? '');
    $eventHash = hash('sha256', implode('|', [$driver, $extIdForHash, (string) ($status ?? ''), $rawSignature]));

    $inserted = \Illuminate\Support\Facades\DB::table('processed_webhook_events')->insertOrIgnore([
      'event_hash' => $eventHash,
      'driver' => $driver,
      'external_id' => $extIdForHash,
      'status' => $status,
      'created_at' => now(),
      'updated_at' => now(),
    ]);

    // insertOrIgnore returns number of rows inserted; if zero, event was already processed
    if ($inserted === 0) {
      return response()->json(['message' => 'duplicate event ignored'], 200);
    }

    $newStatus = $this->paymentGatewayService->mapStatus($status);

    // Use DB transaction to ensure payment + order updates are atomic
    DB::beginTransaction();
    try {
      // Update basic payment fields
      $payment->update([
        'status' => $newStatus,
        'external_payment_id' => $externalPaymentId,
        'provider' => $payment->provider ?: strtoupper(config('services.payments.driver', 'simulation')),
        'paid_at' => ($newStatus === 'PAID') ? now() : $payment->paid_at,
      ]);

      // If payment just became PAID, apply settlement snapshot and affect order
      if ($newStatus === 'PAID') {
        // apply financial snapshot
        $payment->update($this->paymentFinanceService->applySettlementSnapshot($payment));

        $order = $payment->order;

        $eventName = match (strtoupper($payment->payment_type)) {
          'DP' => 'dp_paid',
          'FINAL' => 'final_paid',
          default => 'payment_' . strtolower($payment->payment_type) . '_paid',
        };

        app(N8nNotificationService::class)->dispatch(
          $eventName,
          [
            'order_id' => $order->id,
            'order_code' => $order->order_code,
            'payment_id' => $payment->id,
            'payment_type' => $payment->payment_type,
            'amount' => $payment->amount,
            'order_status' => $order->status,
            'customer_name' => $order->customer?->name,
            'customer_email' => $order->customer?->email,
            'customer_phone' => $order->customer?->phone,
            'provider_name' => $order->provider?->name,
            'provider_email' => $order->provider?->email,
            'provider_phone' => $order->provider?->phone,
          ]
        );

        // Business rule: when DP is paid and order is still CREATED, mark as ACCEPTED
        if ($payment->payment_type === 'DP' && $order && $order->status === 'CREATED') {
          $order->update(['status' => 'ACCEPTED']);
          app(N8nNotificationService::class)->dispatch('order_accepted', [
            'order_id' => $order->id,
            'order_code' => $order->order_code,
            'payment_id' => $payment->id,
            'status' => $order->status,
          ]);
        }

        // Jika FINAL payment sudah dibayar, tutup order (only if order was COMPLETED)
        if ($payment->payment_type === 'FINAL' && $order) {
          $order->update(['status' => 'CLOSED']);
        }
      }

      DB::commit();
    } catch (\Throwable $e) {
      DB::rollBack();
      return response()->json(['message' => 'processing error', 'error' => $e->getMessage()], 500);
    }

    return $this->successResponse(null, 'payment processed', 200);
  }

  /**
   * Get payment status
   */
  public function getPaymentStatus($paymentId)
  {
    $payment = Payment::with(['order.customer', 'order.provider'])->find($paymentId);

    if (!$payment) {
      return $this->notFoundResponse('payment not found');
    }

<<<<<<< HEAD
    if ($response = $this->authorizePaymentAccess($payment, false)) {
      return $response;
    }

    return response()->json([
      'data' => $payment,
    ], 200);
=======
    return $this->successResponse(['payment' => $payment], 'ok', 200);
>>>>>>> a3d33c9406a59b56d71fdef6cba45c270005209b
  }

  /**
   * Capture QRIS image from checkout URL using headless worker
   */
  public function captureQris(Request $request, $paymentId)
  {
    $payment = Payment::find($paymentId);

    if (!$payment) {
      return $this->notFoundResponse('payment not found');
    }

    if ($response = $this->authorizePaymentAccess($payment)) {
      return $response;
    }

    $checkoutUrl = $payment->checkout_url;

    if (!$checkoutUrl) {
      return $this->errorResponse('checkout_url not available for this payment', 400);
    }

    $cacheKey = "qris_capture_result:{$paymentId}";
    $lockKey = "qris_capture_lock:{$paymentId}";

    if (Cache::has($cacheKey)) {
      return $this->successResponse(Cache::get($cacheKey), 'ok', 200);
    }

    if ($payment->qris_image && $payment->qris_captured_at) {
      $result = [
        'message' => 'qris already captured',
        'qris_image' => $payment->qris_image,
        'qris_captured_at' => $payment->qris_captured_at->toDateTimeString(),
      ];
      Cache::put($cacheKey, $result, now()->addMinutes(60));
      return $this->successResponse($result, 'ok', 200);
    }

    if (!Cache::add($lockKey, true, 30)) {
      return $this->errorResponse('capture already in progress, please retry in a moment', 429);
    }

    try {
      // Node script path
      $nodeScript = base_path('tools/capture-qris/index.js');

      if (!file_exists($nodeScript)) {
        return $this->errorResponse('capture worker not installed', 500);
      }

      // Build command (escape URL)
      $escapedUrl = escapeshellarg($checkoutUrl);
      $cmd = "node " . escapeshellarg($nodeScript) . " --url={$escapedUrl} --timeout=20000";

      $output = null;
      $returnVar = null;
      exec($cmd, $output, $returnVar);

      if ($returnVar !== 0) {
        return $this->errorResponse('capture worker failed', 500, ['output' => implode("\n", $output)]);
      }

      $raw = implode("\n", $output);
      $data = json_decode($raw, true);

      if (!$data || empty($data['qris_image'])) {
        return $this->errorResponse('no qris_image captured', 500, ['raw' => $raw]);
      }

      $payment->update([
        'qris_image' => $data['qris_image'],
        'qris_captured_at' => now(),
      ]);

      $result = [
        'message' => 'qris captured',
        'qris_image' => $data['qris_image'],
      ];
      Cache::put($cacheKey, $result, now()->addMinutes(60));
      return $this->successResponse($result, 'qris captured', 200);
    } finally {
      Cache::forget($lockKey);
    }
  }

<<<<<<< HEAD
  private function authorizePaymentAccess(Payment $payment, bool $allowTreasurerRead = true)
  {
    $user = Auth::user();

    if (!$user) {
      return response()->json(['message' => 'unauthenticated'], 401);
    }

    // ADMIN has full access
    if ($user->role === 'ADMIN') {
      return null;
    }

    // TREASURER is allowed read-only access in some contexts
    if ($user->role === 'TREASURER' && $allowTreasurerRead) {
      return null;
    }

    // Otherwise only customer or provider related to order can access
    if ($payment->order?->customer_id !== $user->id && $payment->order?->provider_id !== $user->id) {
      return response()->json(['message' => 'unauthorized'], 403);
    }

    return null;
=======
  /**
   * Capture/confirm QRIS payment manually (untuk testing atau UI confirmation)
   */
  public function captureQris(Request $request, $paymentId)
  {
    $payment = Payment::with(['order'])->find($paymentId);

    if (!$payment) {
      return response()->json(['message' => 'payment not found'], 404);
    }

    // Simulasi payment capture dari frontend
    $payment->update([
      'status' => 'PAID',
      'paid_at' => now(),
    ]);

    $payment->update($this->paymentFinanceService->applySettlementSnapshot($payment));

    // Trigger notification
    app(N8nNotificationService::class)->dispatch(
      'payment_' . strtolower($payment->payment_type) . '_paid',
      [
        'order_id' => $payment->order_id,
        'payment_id' => $payment->id,
        'payment_type' => $payment->payment_type,
        'amount' => $payment->amount,
      ]
    );

    // Close order if FINAL payment
    if ($payment->payment_type === 'FINAL') {
      $payment->order->update(['status' => 'CLOSED']);
    }

    return response()->json(['message' => 'payment captured', 'data' => $payment], 200);
>>>>>>> a3d33c9406a59b56d71fdef6cba45c270005209b
  }
}
