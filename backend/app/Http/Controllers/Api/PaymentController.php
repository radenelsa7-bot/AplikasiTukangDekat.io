<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Services\PaymentGatewayService;
use App\Services\PaymentFinanceService;
use App\Services\N8nNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

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
    $payments = Payment::where('order_id', $orderId)->get();

    return response()->json([
      'data' => $payments,
    ], 200);
  }

  /**
   * Generate QRIS untuk payment
   */
  public function generateQRIS(Request $request, $paymentId)
  {
    $payment = Payment::with(['order.customer', 'order.provider'])->find($paymentId);

    if (!$payment) {
      return response()->json([
        'message' => 'payment not found',
      ], 404);
    }

    $qrisData = $this->paymentGatewayService->generateQrisPayload($payment);

    $payment->update([
      'provider' => $qrisData['provider'] ?? $payment->provider,
      'external_payment_id' => $qrisData['reference'] ?? $payment->external_payment_id,
      'qris_code' => $qrisData['qris_code'] ?? $payment->qris_code,
      'qris_image' => $qrisData['qris_image'] ?? $payment->qris_image,
      'checkout_url' => $qrisData['checkout_url'] ?? $payment->checkout_url,
      'status' => $payment->status === 'UNPAID' ? 'PENDING' : $payment->status,
    ]);

    return response()->json([
      'data' => $qrisData,
    ], 200);
  }

  /**
   * Webhook callback dari payment gateway
   * Endpoint ini menerima notifikasi pembayaran dari Midtrans/Xendit
   */
  public function webhookPaymentCallback(Request $request)
  {
    if (!$this->paymentGatewayService->verifyWebhook($request)) {
      return response()->json(['message' => 'invalid signature'], 403);
    }

    $data = $request->all();

    $paymentId = $data['payment_id'] ?? data_get($data, 'metadata.payment_id');
    $externalPaymentId = $data['transaction_id'] ?? $data['reference'] ?? $data['order_id'] ?? $data['external_payment_id'] ?? null;
    $status = $data['status'] ?? $data['transaction_status'] ?? $data['payment_status'] ?? null;

    if (!$paymentId && !$externalPaymentId) {
      return response()->json(['message' => 'invalid payload'], 400);
    }

    $payment = Payment::when($paymentId, function ($query) use ($paymentId) {
      $query->where('id', $paymentId);
    }, function ($query) use ($externalPaymentId) {
      $query->where('external_payment_id', $externalPaymentId);
    })->first();

    if (!$payment) {
      return response()->json(['message' => 'payment not found'], 404);
    }

    $newStatus = $this->paymentGatewayService->mapStatus($status);

    $payment->update([
      'status' => $newStatus,
      'external_payment_id' => $externalPaymentId,
      'provider' => $payment->provider ?: strtoupper(config('services.payments.driver', 'simulation')),
      'paid_at' => ($newStatus === 'PAID') ? now() : $payment->paid_at,
    ]);

    // Jika payment berhasil, update order status
    if ($newStatus === 'PAID') {
      $payment->update($this->paymentFinanceService->applySettlementSnapshot($payment));

      $order = $payment->order;

      app(N8nNotificationService::class)->dispatch(
        'payment_' . strtolower($payment->payment_type) . '_paid',
        [
          'order_id' => $order->id,
          'payment_id' => $payment->id,
          'payment_type' => $payment->payment_type,
          'amount' => $payment->amount,
          'order_status' => $order->status,
        ]
      );

      // Jika FINAL payment sudah dibayar, tutup order
      if ($payment->payment_type === 'FINAL') {
        $order->update(['status' => 'CLOSED']);
      }
    }

    return response()->json(['message' => 'payment processed'], 200);
  }

  /**
   * Get payment status
   */
  public function getPaymentStatus($paymentId)
  {
    $payment = Payment::with(['order.customer', 'order.provider'])->find($paymentId);

    if (!$payment) {
      return response()->json([
        'message' => 'payment not found',
      ], 404);
    }

    return response()->json([
      'data' => $payment,
    ], 200);
  }

  /**
   * Capture QRIS image from checkout URL using headless worker
   */
  public function captureQris(Request $request, $paymentId)
  {
    $payment = Payment::find($paymentId);

    if (!$payment) {
      return response()->json(['message' => 'payment not found'], 404);
    }

    $checkoutUrl = $payment->checkout_url;

    if (!$checkoutUrl) {
      return response()->json(['message' => 'checkout_url not available for this payment'], 400);
    }

    $cacheKey = "qris_capture_result:{$paymentId}";
    $lockKey = "qris_capture_lock:{$paymentId}";

    if (Cache::has($cacheKey)) {
      return response()->json(Cache::get($cacheKey), 200);
    }

    if ($payment->qris_image && $payment->qris_captured_at) {
      $result = [
        'message' => 'qris already captured',
        'qris_image' => $payment->qris_image,
        'qris_captured_at' => $payment->qris_captured_at->toDateTimeString(),
      ];
      Cache::put($cacheKey, $result, now()->addMinutes(60));
      return response()->json($result, 200);
    }

    if (!Cache::add($lockKey, true, 30)) {
      return response()->json(['message' => 'capture already in progress, please retry in a moment'], 429);
    }

    try {
      // Node script path
      $nodeScript = base_path('tools/capture-qris/index.js');

      if (!file_exists($nodeScript)) {
        return response()->json(['message' => 'capture worker not installed'], 500);
      }

      // Build command (escape URL)
      $escapedUrl = escapeshellarg($checkoutUrl);
      $cmd = "node " . escapeshellarg($nodeScript) . " --url={$escapedUrl} --timeout=20000";

      $output = null;
      $returnVar = null;
      exec($cmd, $output, $returnVar);

      if ($returnVar !== 0) {
        return response()->json(['message' => 'capture worker failed', 'output' => implode("\n", $output)], 500);
      }

      $raw = implode("\n", $output);
      $data = json_decode($raw, true);

      if (!$data || empty($data['qris_image'])) {
        return response()->json(['message' => 'no qris_image captured', 'raw' => $raw], 500);
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
      return response()->json($result, 200);
    } finally {
      Cache::forget($lockKey);
    }
  }
}
