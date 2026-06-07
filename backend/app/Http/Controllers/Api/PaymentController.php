<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Services\PaymentGatewayService;
use App\Services\PaymentFinanceService;
use App\Services\N8nNotificationService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use App\Traits\ApiResponse;

class PaymentController extends Controller
{
  use ApiResponse;
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

    return $this->success($payments, 'Payments for order');
  }

  /**
   * Generate QRIS untuk payment
   */
  public function generateQRIS(Request $request, $paymentId)
  {
    $payment = Payment::with(['order.customer', 'order.provider'])->find($paymentId);

    if (!$payment) {
      return $this->notFound('Payment not found');
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
    return $this->success($qrisData, 'QRIS generated');
  }

  /**
   * Webhook callback dari payment gateway
   * Endpoint ini menerima notifikasi pembayaran dari Midtrans/Xendit
   */
  public function webhookPaymentCallback(Request $request)
  {
    if (!$this->paymentGatewayService->verifyWebhook($request)) {
      return $this->forbidden('Invalid signature');
    }

    $data = $request->all();

    $paymentId = $data['payment_id'] ?? data_get($data, 'metadata.payment_id');
    $externalPaymentId = $data['transaction_id'] ?? $data['reference'] ?? $data['order_id'] ?? $data['external_payment_id'] ?? null;
    $status = $data['status'] ?? $data['transaction_status'] ?? $data['payment_status'] ?? null;

    if (!$paymentId && !$externalPaymentId) {
      return $this->validationError(['payment_id' => ['Invalid payload: missing payment identifiers']]);
    }

    $payment = Payment::when($paymentId, function ($query) use ($paymentId) {
      $query->where('id', $paymentId);
    }, function ($query) use ($externalPaymentId) {
      $query->where('external_payment_id', $externalPaymentId);
    })->first();

    if (!$payment) {
      return $this->notFound('Payment not found');
    }

    $newStatus = $this->paymentGatewayService->mapStatus($status);

    if ($payment->status === $newStatus) {
      return $this->success(['status' => $payment->status], 'Payment already processed');
    }

    if ($payment->status === 'PAID' && $newStatus !== 'PAID') {
      return $this->success(['status' => $payment->status], 'Payment already settled');
    }

    $previousStatus = $payment->status;

    DB::transaction(function () use ($payment, $newStatus, $externalPaymentId, $previousStatus) {
      $payment->update([
        'status' => $newStatus,
        'external_payment_id' => $externalPaymentId,
        'provider' => $payment->provider ?: strtoupper(config('services.payments.driver', 'simulation')),
        'paid_at' => ($newStatus === 'PAID') ? now() : $payment->paid_at,
      ]);

      if ($newStatus === 'PAID' && $previousStatus !== 'PAID') {
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

        if ($payment->payment_type === 'FINAL') {
          $order->update(['status' => 'CLOSED']);
        }
      }
    });

    return $this->success(null, 'Payment processed');
  }

  /**
   * Get payment status
   */
  public function getPaymentStatus($paymentId)
  {
    $payment = Payment::with(['order.customer', 'order.provider'])->find($paymentId);

    if (!$payment) {
      return $this->notFound('Payment not found');
    }

    return $this->success($payment, 'Payment status');
  }

  /**
   * Capture QRIS image from checkout URL using headless worker
   */
  public function captureQris(Request $request, $paymentId)
  {
    $payment = Payment::find($paymentId);

    if (!$payment) {
      return $this->notFound('Payment not found');
    }

    $checkoutUrl = $payment->checkout_url;

    if (!$checkoutUrl) {
      return $this->error('checkout_url not available for this payment', 400);
    }

    $cacheKey = "qris_capture_result:{$paymentId}";
    $lockKey = "qris_capture_lock:{$paymentId}";

    if (Cache::has($cacheKey)) {
      return $this->success(Cache::get($cacheKey), 'QRIS capture cached');
    }

    if ($payment->qris_image && $payment->qris_captured_at) {
      $result = [
        'qris_image' => $payment->qris_image,
        'qris_captured_at' => $payment->qris_captured_at->toDateTimeString(),
      ];
      Cache::put($cacheKey, $result, now()->addMinutes(60));
      return $this->success($result, 'QRIS already captured');
    }

    if (!Cache::add($lockKey, true, 30)) {
      return $this->tooManyRequests('Capture already in progress, please retry in a moment');
    }

    try {
      // Node script path
      $nodeScript = base_path('tools/capture-qris/index.js');

      if (!file_exists($nodeScript)) {
        return $this->internalServerError('Capture worker not installed');
      }

      // Build command (escape URL)
      $escapedUrl = escapeshellarg($checkoutUrl);
      $cmd = "node " . escapeshellarg($nodeScript) . " --url={$escapedUrl} --timeout=20000";

      $output = null;
      $returnVar = null;
      exec($cmd, $output, $returnVar);

      if ($returnVar !== 0) {
        return $this->internalServerError('Capture worker failed', null);
      }

      $raw = implode("\n", $output);
      $data = json_decode($raw, true);

      if (!$data || empty($data['qris_image'])) {
        return $this->internalServerError('No qris_image captured');
      }

      $payment->update([
        'qris_image' => $data['qris_image'],
        'qris_captured_at' => now(),
      ]);

      $result = [
        'qris_image' => $data['qris_image'],
      ];
      Cache::put($cacheKey, $result, now()->addMinutes(60));
      return $this->success($result, 'QRIS captured');
    } finally {
      Cache::forget($lockKey);
    }
  }
}
