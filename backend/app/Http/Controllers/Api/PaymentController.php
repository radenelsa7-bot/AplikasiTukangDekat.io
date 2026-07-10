<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\Payment;
use App\Services\PaymentGatewayService;
use App\Services\PaymentFinanceService;
use App\Services\N8nNotificationService;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class PaymentController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly PaymentGatewayService $paymentGatewayService,
        private readonly PaymentFinanceService $paymentFinanceService,
    ) {}

    public function getPayments($orderId)
    {
        $order = Order::with(['customer', 'provider'])->find($orderId);

        if (!$order) {
            return response()->json(['message' => 'order not found'], 404);
        }

        if ($response = $this->authorizePaymentAccessByOrder($order)) {
            return $response;
        }

        $payments = Payment::where('order_id', $orderId)->get();

        return $this->successResponse(['payments' => $payments], 'ok', 200);
    }

    public function generateQRIS(Request $request, $paymentId)
    {
        $payment = Payment::with(['order.customer', 'order.provider'])->find($paymentId);

        if (!$payment) {
            return $this->notFoundResponse('payment not found');
        }

        if ($payment->status === 'PAID') {
            return $this->errorResponse('Payment already paid', 400);
        }

        // Return cached checkout_url if already generated (avoid duplicate Snap transactions)
        if ($payment->checkout_url && $payment->status !== 'UNPAID') {
            return $this->successResponse(['qris' => [
                'provider' => $payment->provider ?? 'MIDTRANS',
                'reference' => $payment->external_payment_id,
                'payment_id' => $payment->id,
                'amount' => $payment->amount,
                'payment_type' => $payment->payment_type,
                'qris_code' => $payment->qris_code,
                'qris_image' => $payment->qris_image,
                'checkout_url' => $payment->checkout_url,
                'qris_hint' => $payment->checkout_url ? 'open_checkout_url' : 'show_qris_code',
            ]], 'ok', 200);
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

        return $this->successResponse(['qris' => $qrisData], 'ok', 200);
    }

    public function confirmPayment(Request $request, $paymentId)
    {
        $payment = Payment::with(['order.customer', 'order.provider'])->find($paymentId);

        if (!$payment) {
            return $this->notFoundResponse('payment not found');
        }

        if ($payment->status === 'PAID') {
            return $this->successResponse(['payment' => $payment], 'Payment already confirmed', 200);
        }

        // Requirement: FINAL payment hanya bisa diproses setelah customer menyetujui harga akhir.
        if (strtoupper((string) $payment->payment_type) === 'FINAL') {
            $approval = \App\Models\FinalPriceApproval::where('order_id', $payment->order_id)
                ->latest('id')
                ->first();

            if (!$approval || $approval->approval_status !== 'APPROVED') {
                return $this->errorResponse('Customer approval for final price is required', 409);
            }
        }


        // Check Midtrans transaction status if using Midtrans
        if ($this->paymentGatewayService->driver() === 'midtrans') {
            $serverKey = (string) config('services.payments.midtrans_server_key', '');
            $isProduction = (bool) config('services.payments.midtrans_is_production', false);

            if ($serverKey !== '' && $payment->external_payment_id) {
                $statusUrl = $isProduction
                    ? 'https://api.midtrans.com/v2/' . $payment->external_payment_id . '/status'
                    : 'https://api.sandbox.midtrans.com/v2/' . $payment->external_payment_id . '/status';

                try {
                    $response = \Illuminate\Support\Facades\Http::withBasicAuth($serverKey, '')
                        ->acceptJson()
                        ->timeout(15)
                        ->get($statusUrl)
                        ->json();

                    $txStatus = $response['transaction_status'] ?? null;
                    $mappedStatus = $this->paymentGatewayService->mapStatus($txStatus);

                    if ($mappedStatus === 'PAID') {
                        return $this->markPaymentAsPaid($payment);
                    }

                    return $this->successResponse([
                        'payment' => $payment,
                        'midtrans_status' => $txStatus,
                    ], 'Payment belum terdeteksi di Midtrans. Status: ' . ($txStatus ?? 'unknown'), 200);
                } catch (\Throwable $e) {
                    // Midtrans status check failed, fall through to manual confirmation
                }
            }
        }

        // For simulation mode or if Midtrans check fails, mark as paid directly
        return $this->markPaymentAsPaid($payment);
    }

    private function markPaymentAsPaid(Payment $payment)
    {
        DB::beginTransaction();
        try {
            $payment->update([
                'status' => 'PAID',
                'paid_at' => now(),
                'provider' => $payment->provider ?: strtoupper($this->paymentGatewayService->driver()),
            ]);

            $payment->update($this->paymentFinanceService->applySettlementSnapshot($payment));

            $order = $payment->order;
            $eventName = match (strtoupper($payment->payment_type)) {
                'DP' => 'dp_paid',
                'FINAL' => 'final_paid',
                default => 'payment_' . strtolower($payment->payment_type) . '_paid',
            };

            app(N8nNotificationService::class)->dispatch($eventName, [
                'order_id' => $order->id,
                'order_code' => $order->order_code,
                'payment_id' => $payment->id,
                'payment_type' => $payment->payment_type,
                'amount' => $payment->amount,
            ]);

            if ($payment->payment_type === 'FINAL') {
                $oldStatus = $order->status;
                $order->update(['status' => 'CLOSED']);
                OrderStatusLog::create([
                    'order_id' => $order->id,
                    'old_status' => $oldStatus,
                    'new_status' => 'CLOSED',
                    'changed_by' => Auth::id(),
                    'reason' => 'Payment confirmed by user',
                ]);
            }


            DB::commit();
            return $this->successResponse(['payment' => $payment->fresh()], 'Payment confirmed', 200);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'Failed to confirm payment', 'error' => $e->getMessage()], 500);
        }
    }

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

        $driver = $this->paymentGatewayService->driver();
        $eventHash = hash('sha256', implode('|', [$driver, $externalPaymentId ?? $paymentId, (string) $status]));

        $isProcessed = DB::table('processed_webhook_events')->where('event_hash', $eventHash)->exists();
        if ($isProcessed) {
            return response()->json(['message' => 'duplicate event ignored'], 200);
        }

        $newStatus = $this->paymentGatewayService->mapStatus($status);

        DB::beginTransaction();
        try {
            DB::table('processed_webhook_events')->insert([
                'event_hash' => $eventHash,
                'driver' => $driver,
                'external_id' => $externalPaymentId ?? $paymentId,
                'status' => $status,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $payment->update([
                'status' => $newStatus,
                'external_payment_id' => $externalPaymentId,
                'provider' => $payment->provider ?: strtoupper(config('services.payments.driver', 'simulation')),
                'paid_at' => ($newStatus === 'PAID') ? now() : $payment->paid_at,
            ]);

            if ($newStatus === 'PAID') {
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
            }

            if ($payment->payment_type === 'FINAL') {
                $order = $payment->order;
                $oldStatus = $order->status;
                $order->update(['status' => 'CLOSED']);
                OrderStatusLog::create([
                    'order_id' => $order->id,
                    'old_status' => $oldStatus,
                    'new_status' => 'CLOSED',
                    'changed_by' => null,
                    'reason' => 'Final payment received via webhook',
                ]);
            }

            DB::commit();
            return $this->successResponse(null, 'payment processed', 200);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'processing error', 'error' => $e->getMessage()], 500);
        }
    }

    public function getPaymentStatus($paymentId)
    {
        $payment = Payment::with(['order.customer', 'order.provider'])->find($paymentId);

        if (!$payment) {
            return $this->notFoundResponse('payment not found');
        }

        return $this->successResponse(['payment' => $payment], 'ok', 200);
    }

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
            return $this->successResponse($result, 'ok', 200);
        }

        if (!Cache::add($lockKey, true, 30)) {
            return $this->errorResponse('capture already in progress, please retry in a moment', 429);
        }

        try {
            $nodeScript = base_path('tools/capture-qris/index.js');
            if (!file_exists($nodeScript)) {
                return $this->errorResponse('worker not installed', 500);
            }

            $escapedUrl = escapeshellarg($checkoutUrl);
            $cmd = "node " . escapeshellarg($nodeScript) . " --url={$escapedUrl} --timeout=20000";

            $output = null;
            $returnVar = null;
            exec($cmd, $output, $returnVar);

            if ($returnVar !== 0) {
                return $this->errorResponse('capture failed', 500, ['output' => $output]);
            }

            $raw = implode("\n", $output);
            $data = json_decode($raw, true);
            if (!$data || empty($data['qris_image'])) {
                return $this->errorResponse('no image captured', 500);
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

    public function captureQrisManual(Request $request, $paymentId)
    {
        if (config('app.env') === 'production' && Auth::user()?->role !== 'ADMIN') {
            return $this->forbiddenResponse('Manual capture is for testing only');
        }

        $payment = Payment::with(['order'])->find($paymentId);
        if (!$payment) {
            return response()->json(['message' => 'payment not found'], 404);
        }

        $payment->update([
            'status' => 'PAID',
            'paid_at' => now(),
        ]);

        $payment->update($this->paymentFinanceService->applySettlementSnapshot($payment));

        app(N8nNotificationService::class)->dispatch(
            'payment_' . strtolower($payment->payment_type) . '_paid',
            [
                'order_id' => $payment->order_id,
                'payment_id' => $payment->id,
                'payment_type' => $payment->payment_type,
                'amount' => $payment->amount,
            ]
        );

        if ($payment->payment_type === 'FINAL') {
            $order = $payment->order;
            $oldStatus = $order->status;
            $order->update(['status' => 'CLOSED']);
            OrderStatusLog::create([
                'order_id' => $order->id,
                'old_status' => $oldStatus,
                'new_status' => 'CLOSED',
                'changed_by' => Auth::id(),
                'reason' => 'Final payment captured manually',
            ]);
        }

        return $this->successResponse(['payment' => $payment], 'payment captured', 200);
    }

    private function authorizePaymentAccessByOrder($order)
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json(['message' => 'unauthenticated'], 401);
        }

        if ($user->role === 'ADMIN' || $user->role === 'TREASURER') {
            return null;
        }

        if ($order->customer_id === $user->id || $order->provider_id === $user->id) {
            return null;
        }

        return response()->json(['message' => 'unauthorized'], 403);
    }

    private function authorizePaymentAccess(Payment $payment, bool $allowTreasurerRead = true)
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json(['message' => 'unauthenticated'], 401);
        }

        if ($user->role === 'ADMIN') {
            return null;
        }

        if ($user->role === 'TREASURER' && $allowTreasurerRead) {
            return null;
        }

        $order = $payment->order;
        if ($order && ($order->customer_id === $user->id || $order->provider_id === $user->id)) {
            return null;
        }

        return response()->json(['message' => 'unauthorized'], 403);
    }
}
