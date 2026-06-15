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

        return $this->successResponse(['payment' => $payment], 'ok', 200);
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
                'qris_image' => $payment->qris_image,
                'qris_captured_at' => $payment->qris_captured_at->toDateTimeString(),
            ];
            Cache::put($cacheKey, $result, now()->addMinutes(60));
            return $this->success($result, 'QRIS already captured');
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
                'qris_image' => $data['qris_image'],
            ];
            Cache::put($cacheKey, $result, now()->addMinutes(60));
            return $this->successResponse($result, 'qris captured', 200);
        } finally {
            Cache::forget($lockKey);
        }
    }

    /**
     * Capture/confirm QRIS payment manually (untuk testing atau UI confirmation)
     */
    public function captureQrisManual(Request $request, $paymentId)
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
