<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Order\SubmitFinalPriceUpdateRequest;
use App\Models\FinalPriceApproval;
use App\Models\FinalPriceLog;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class FinalPriceUpdateController extends Controller
{
    use ApiResponse;

    public function submit(SubmitFinalPriceUpdateRequest $request, int $orderId): JsonResponse
    {
        $user = Auth::user();

        $order = Order::with(['payments'])->find($orderId);
        if (!$order) {
            return $this->notFound('Order not found');
        }

        if (!$this->isAssignedToCurrentProvider((int) $order->provider_id, $user)) {
            return $this->forbidden('Unauthorized');
        }

        // Hanya saat order sudah COMPLETED (provider sudah selesai kerja) kita izinkan submit/update harga akhir
        if ($order->status !== 'COMPLETED') {
            return $this->conflict('Final price can only be submitted after order is completed');
        }

        $validated = $request->validated();
        $proposed = (int) $validated['proposed_final_price'];

        // DP amount (opsional untuk validasi jumlah minimal, tapi cukup simpan log)
        $dpPayment = $order->payments()->where('payment_type', 'DP')->first();
        $dpAmount = $dpPayment?->amount ?? 0;

        try {
            return DB::transaction(function () use ($order, $proposed, $user, $dpAmount) {
                // 1) Simpan history perubahan yang diajukan provider
                FinalPriceLog::create([
                    'order_id' => $order->id,
                    'proposed_final_price' => $proposed,
                    'action' => 'UPDATE',
                    'submitted_by' => $user->id,
                ]);

                // 2) Update approval agar kembali PENDING untuk customer approve ulang
                FinalPriceApproval::updateOrCreate(
                    ['order_id' => $order->id],
                    [
                        'proposed_final_price' => $proposed,
                        'approval_status' => 'PENDING',
                        'approved_by' => null,
                    ]
                );

                // 3) Catat event log internal (optional, tapi kita simpan sebagai status log tanpa ubah status)
                OrderStatusLog::create([
                    'order_id' => $order->id,
                    'old_status' => $order->status,
                    'new_status' => $order->status,
                    'changed_by' => $user->id,
                    'reason' => 'Provider submitted updated final price; requires customer approval',
                ]);

                return $this->success(
                    [
                        'status' => 'PENDING',
                        'proposed_final_price' => $proposed,
                        'dp_amount' => $dpAmount,
                    ],
                    'Final price submitted; customer approval required'
                );
            });
        } catch (\Throwable $e) {
            Log::error('Final price submit error: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return $this->internalServerError('Failed to submit final price');
        }
    }

    private function providerIdentifierSet(User $user): array
    {
        $ids = [$user->id];
        $profileId = $user->providerProfile?->id;
        if ($profileId) {
            $ids[] = $profileId;
        }

        return array_values(array_unique(array_map('intval', $ids)));
    }

    private function isAssignedToCurrentProvider(int $providerIdentifier, User $user): bool
    {
        return in_array($providerIdentifier, $this->providerIdentifierSet($user), true);
    }
}
