<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Services\PaymentGatewayService;
use App\Services\PaymentFinanceService;
use App\Services\N8nNotificationService;
use Illuminate\Http\Request;

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
      'status' => $payment->status === 'UNPAID' ? 'PENDING' : $payment->status,
      'qris_code' => $qrisData['qris_code'] ?? $payment->qris_code,
      'qris_image' => $qrisData['qris_image'] ?? $payment->qris_image,
      'checkout_url' => $qrisData['checkout_url'] ?? $payment->checkout_url,
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
  }
}
