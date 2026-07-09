<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Order\ApproveFinalPriceRequest;
use App\Models\FinalPriceApproval;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\Payment;
use App\Services\N8nNotificationService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class OrderFinalPriceController extends Controller
{
    use ApiResponse;

    /**
     * Customer approve/reject harga final sebelum pelunasan (FINAL payment).
     */
    public function decide(ApproveFinalPriceRequest $request, int $orderId): JsonResponse
    {
        $user = Auth::user();

        $order = Order::with(['payments'])->find($orderId);
        if (!$order) {
            return $this->notFound('Order not found');
        }

        if ($order->customer_id !== $user->id) {
            return $this->forbidden('Unauthorized');
        }

        $approval = FinalPriceApproval::where('order_id', $orderId)
            ->latest('id')
            ->first();

        if (!$approval) {
            return $this->notFound('Final price approval not found');
        }

        if ($approval->approval_status !== 'PENDING') {
            return $this->conflict('Final price already decided');
        }

        $validated = $request->validated();
        $action = $validated['action'];
        $reason = $validated['reason'] ?? null;

        try {
            return DB::transaction(function () use ($approval, $order, $validated, $user, $reason) {
                if ($validated['action'] === 'reject') {
                    $approval->update([
                        'approval_status' => 'REJECTED',
                        'approved_by' => $user->id,
                    ]);

                    OrderStatusLog::create([
                        'order_id' => $order->id,
                        'old_status' => $order->status,
                        'new_status' => $order->status,
                        'changed_by' => $user->id,
                        'reason' => $reason ?: 'Customer rejected final price',
                    ]);

                    app(N8nNotificationService::class)->dispatch('final_price_rejected', [
                        'order_id' => $order->id,
                        'order_code' => $order->order_code,
                        'customer_id' => $order->customer_id,
                        'provider_id' => $order->provider_id,
                    ]);

                    return $this->success(['status' => 'REJECTED'], 'Final price rejected');
                }

                // approve
                $approval->update([
                    'approval_status' => 'APPROVED',
                    'approved_by' => $user->id,
                ]);

                // create FINAL payment only when approved and not already existing
                $existsFinal = $order->payments()
                    ->where('payment_type', 'FINAL')
                    ->exists();

                if (!$existsFinal) {
                    $dpPayment = $order->payments()->where('payment_type', 'DP')->first();
                    $dpAmount = $dpPayment?->amount ?? 0;

                    $finalAmount = max(0, (int) $order->final_price - (int) $dpAmount);
                    if ($finalAmount > 0) {
                        Payment::create([
                            'order_id' => $order->id,
                            'payment_type' => 'FINAL',
                            'amount' => $finalAmount,
                            'status' => 'UNPAID',
                        ]);
                    }
                }

                app(N8nNotificationService::class)->dispatch('final_price_approved', [
                    'order_id' => $order->id,
                    'order_code' => $order->order_code,
                    'customer_id' => $order->customer_id,
                    'provider_id' => $order->provider_id,
                ]);

                return $this->success(['status' => 'APPROVED'], 'Final price approved');
            });
        } catch (\Throwable $e) {
            Log::error('Final price decision error: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return $this->internalServerError('Failed to decide final price');
        }
    }
}
