<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Order\CompleteOrderRequest;
use App\Http\Requests\Order\CreateOrderRequest;
use App\Http\Requests\Order\RespondToOrderRequest;
use App\Models\Order;
use App\Models\OrderAttachment;
use App\Models\OrderStatusLog;
use Illuminate\Support\Facades\Storage;
use App\Models\Payment;
use App\Models\User;
use App\Services\N8nNotificationService;
use App\Services\PaymentFinanceService;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly PaymentFinanceService $paymentFinanceService,
    ) {}

    /**
     * Buat order baru
     */
    public function createOrder(CreateOrderRequest $request)
    {
        $user = Auth::user();
        try {
            $validated = $request->validated();

            [$provider, $providerProfile] = $this->resolveProviderAssignment($validated['provider_id']);

            if (!$providerProfile) {
                return $this->validationError([
                    'provider_id' => ['Sepertinya Provider kita belum tersedia disana'],
                ]);
            }

            $kecamatanId = (int) $validated['kecamatan_id'];
            $hasCoverage = \App\Models\ProviderCoverage::where('provider_profile_id', $providerProfile->id)
                ->where('kecamatan_id', $kecamatanId)
                ->where('is_active', true)
                ->exists();

            if (!$hasCoverage) {
                return $this->validationError([
                    'kecamatan_id' => ['Sepertinya Provider kita belum tersedia disana'],
                ]);
            }

            $result = DB::transaction(function () use ($request, $validated, $user, $provider, $providerProfile) {
                $order = Order::create([
                    'order_code' => Order::generateCode(),
                    'customer_id' => $user->id,
                    'provider_id' => $validated['provider_id'],
                    'category_id' => $validated['category_id'],
                    'provider_service_id' => $validated['provider_service_id'] ?? null,
                    'kota_id' => $validated['kota_id'],
                    'kecamatan_id' => $validated['kecamatan_id'],
                    'schedule_at' => $validated['schedule_at'],
                    'address' => $validated['address'],
                    'customer_latitude' => $validated['customer_latitude'] ?? null,
                    'customer_longitude' => $validated['customer_longitude'] ?? null,
                    'provider_latitude' => $providerProfile?->latitude,
                    'provider_longitude' => $providerProfile?->longitude,
                    'notes' => $validated['notes'] ?? null,
                    'damage_level' => $validated['damage_level'] ?? null,
                    'damage_description' => $validated['damage_description'] ?? null,
                    'estimated_price_min' => $validated['estimated_price_min'] ?? $validated['estimated_price'],
                    'estimated_price_max' => $validated['estimated_price_max'] ?? $validated['estimated_price'],
                    'estimated_price' => $validated['estimated_price'],
                    'status' => 'CREATED',
                ]);

                $dpAmount = intval($validated['estimated_price'] * 0.5);
                Payment::create([
                    'order_id' => $order->id,
                    'payment_type' => 'DP',
                    'amount' => $dpAmount,
                    'status' => 'UNPAID',
                ]);

                foreach (($validated['attachment_urls'] ?? []) as $url) {
                    OrderAttachment::create([
                        'order_id' => $order->id,
                        'file_url' => $url,
                        'file_type' => 'damage_photo_url',
                    ]);
                }

                foreach (($validated['damage_photos'] ?? []) as $photo) {
                    $path = $photo->store('order-damage-photos', 'public');
                    OrderAttachment::create([
                        'order_id' => $order->id,
                        'file_url' => $path,
                        'file_type' => 'damage_photo',
                    ]);
                }

                OrderStatusLog::create([
                    'order_id' => $order->id,
                    'old_status' => null,
                    'new_status' => 'CREATED',
                    'changed_by' => $user->id,
                ]);

                // Process attachment data URLs (if any were provided)
                if (!empty($validated['attachment_urls']) && is_array($validated['attachment_urls'])) {
                    foreach ($validated['attachment_urls'] as $attachment) {
                        try {
                            if (is_string($attachment) && str_starts_with($attachment, 'data:')) {
                                // Data URL: data:<mime>;base64,<data>
                                if (preg_match('/^data:(image\/(png|jpeg));base64,(.*)$/', $attachment, $matches)) {
                                    $mime = $matches[1];
                                    $ext = $matches[2] === 'png' ? 'png' : 'jpg';
                                    $b64 = $matches[3];
                                    $data = base64_decode($b64);
                                    $fileName = sprintf('%s_%s.%s', $order->id, uniqid(), $ext);
                                    $path = 'orders/' . $fileName;
                                    Storage::disk('public')->put($path, $data);
                                    OrderAttachment::create([
                                        'order_id' => $order->id,
                                        'file_url' => $path,
                                        'file_type' => $mime,
                                        'purpose' => 'CUSTOMER_DAMAGE',
                                    ]);
                                }
                            } elseif (is_string($attachment) && filter_var($attachment, FILTER_VALIDATE_URL)) {
                                // External URL - save as-is
                                OrderAttachment::create([
                                    'order_id' => $order->id,
                                    'file_url' => $attachment,
                                    'file_type' => 'external',
                                    'purpose' => 'CUSTOMER_DAMAGE',
                                ]);
                            } elseif (is_string($attachment) && !empty($attachment)) {
                                // Assume it's a previously uploaded storage path like 'orders/xyz.jpg'
                                OrderAttachment::create([
                                    'order_id' => $order->id,
                                    'file_url' => $attachment,
                                    'file_type' => 'uploaded',
                                    'purpose' => 'CUSTOMER_DAMAGE',
                                ]);
                            }
                        } catch (\Throwable $e) {
                            // continue on attachment save error but log it
                            Log::warning('Failed to save order attachment: ' . $e->getMessage());
                        }
                    }
                }

                // If files were uploaded in the same request, store them
                if ($request->hasFile('files')) {
                    foreach ($request->file('files') as $file) {
                        try {
                            /** @var UploadedFile $file */
                            $ext = $file->getClientOriginalExtension() ?: 'jpg';
                            $fileName = sprintf('%s_%s.%s', $order->id, uniqid(), $ext);
                            $path = $file->storeAs('orders', $fileName, 'public');
                            OrderAttachment::create([
                                'order_id' => $order->id,
                                'file_url' => $path,
                                'file_type' => $file->getClientMimeType() ?? 'image/jpeg',
                                'purpose' => 'CUSTOMER_DAMAGE',
                            ]);
                        } catch (\Throwable $e) {
                            Log::warning('Failed to store uploaded file: ' . $e->getMessage());
                        }
                    }
                }

                return ['order' => $order, 'dpAmount' => $dpAmount];
            });

            $order = $result['order'];
            $dpAmount = $result['dpAmount'];

            app(N8nNotificationService::class)->dispatch('order_created', [
                'order_id' => $order->id,
                'order_code' => $order->order_code,
                'customer_id' => $order->customer_id,
                'provider_id' => $order->provider_id,
                'estimated_price' => $order->estimated_price,
                'dp_amount' => $dpAmount,
                'status' => $order->status,
            ]);

            $order->load(['payments', 'attachments', 'customer', 'provider']);
            return $this->success($order, 'Order created', 201);
        } catch (ModelNotFoundException $e) {
            return $this->validationError(['provider_id' => ['Selected provider not found or not active']]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->validationError($e->errors());
        } catch (\Throwable $e) {
            Log::error('Create order error: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return $this->internalServerError('Failed to create order');
        }
    }

    /**
     * Get order berdasarkan ID
     */
    public function getOrder($orderId)
    {
        $order = Order::with(['customer', 'provider', 'payments', 'statusLogs', 'attachments', 'finalPriceApproval'])
            ->find($orderId);

        if (!$order) {
            return $this->notFound('Order not found');
        }

        $order->load('attachments');
        return $this->success($order, 'Order retrieved');
    }

    /**
     * Get orders dari customer atau provider
     */
    public function getMyOrders(Request $request)
    {
        $user = Auth::user();

        if ($user->role === 'CUSTOMER') {
            $orders = Order::where('customer_id', $user->id)
                ->with(['provider', 'payments'])
                ->with('finalPriceApproval')
                ->latest()
                ->get();
        } elseif ($user->role === 'PROVIDER') {
            $providerIds = $this->providerIdentifierSet($user);
            $orders = Order::whereIn('provider_id', $providerIds)
                ->with(['customer', 'payments'])
                ->with('finalPriceApproval')
                ->latest()
                ->get();
        } else {
            return $this->forbidden('Unauthorized');
        }

        return $this->success($orders, 'Orders retrieved');
    }

    /**
     * Upload attachments (multipart) and return stored paths.
     */
    public function uploadAttachments(Request $request)
    {
        $user = $request->user();
        if (!$user) return $this->forbidden('Unauthorized');

        $request->validate([
            'files' => 'required|array|max:10',
            'files.*' => 'required|file|mimes:jpeg,jpg,png|max:5120', // max 5MB per file
        ]);

        $stored = [];
        foreach ($request->file('files') as $file) {
            try {
                /** @var UploadedFile $file */
                $ext = $file->getClientOriginalExtension();
                $fileName = sprintf('%s_%s.%s', $user->id, uniqid(), $ext);
                $path = $file->storeAs('orders', $fileName, 'public');
                $stored[] = $path;
            } catch (\Throwable $e) {
                Log::warning('Attachment upload failed: ' . $e->getMessage());
            }
        }

        return $this->success(['file_urls' => $stored, 'public_urls' => array_map(fn($p) => url('/storage/' . $p), $stored)], 'Files uploaded');
    }

    /**
     * Provider terima/tolak order
     */
    public function respondToOrder(RespondToOrderRequest $request, $orderId)
    {
        $user = Auth::user();

        $order = Order::with(['customer', 'payments'])->find($orderId);

        if (!$order) {
            return $this->notFound('Order not found');
        }

        if (!$this->isAssignedToCurrentProvider($order->provider_id, $user)) {
            return $this->forbidden('Unauthorized');
        }

        if ($order->status !== 'CREATED') {
            return $this->conflict('Order cannot be responded to in its current status');
        }

        $validated = $request->validated();

        try {
            return DB::transaction(function () use ($order, $validated, $user) {
                if ($validated['action'] === 'accept') {
                    $oldStatus = $order->status;
                    $order->update(['status' => 'ACCEPTED']);
                    $this->refreshProviderAvailability($order->provider_id);

                    $otherOrders = Order::where('provider_id', $order->provider_id)
                        ->where('id', '!=', $order->id)
                        ->where('status', 'CREATED')
                        ->get();

                    foreach ($otherOrders as $otherOrder) {
                        $otherOldStatus = $otherOrder->status;
                        $otherOrder->update([
                            'status' => 'CANCELLED',
                            'queue_note' => 'Provider sudah menerima pesanan lain terlebih dahulu. Silakan pilih provider lain tanpa mengisi ulang kebutuhan.',
                        ]);
                        OrderStatusLog::create([
                            'order_id' => $otherOrder->id,
                            'old_status' => $otherOldStatus,
                            'new_status' => 'CANCELLED',
                            'changed_by' => $user->id,
                            'reason' => 'Provider accepted another queued order',
                        ]);
                    }

                    OrderStatusLog::create([
                        'order_id' => $order->id,
                        'old_status' => $oldStatus,
                        'new_status' => 'ACCEPTED',
                        'changed_by' => $user->id,
                    ]);

                    app(N8nNotificationService::class)->dispatch('order_accepted', [
                        'order_id' => $order->id,
                        'order_code' => $order->order_code,
                        'provider_id' => $order->provider_id,
                        'status' => $order->status,
                    ]);

                    return $this->success(['status' => $order->status], 'Order accepted');
                }

                $oldStatus = $order->status;
                $order->update([
                    'status' => 'CANCELLED',
                    'queue_note' => 'Provider menolak pesanan ini. Silakan pilih provider lain tanpa mengisi ulang kebutuhan.',
                ]);
                OrderStatusLog::create([
                    'order_id' => $order->id,
                    'old_status' => $oldStatus,
                    'new_status' => 'CANCELLED',
                    'changed_by' => $user->id,
                    'reason' => $validated['reason'] ?? 'Rejected by provider',
                ]);

                $refundPayments = $order->payments()
                    ->where('payment_type', 'DP')
                    ->where('status', 'PAID')
                    ->get();

                foreach ($refundPayments as $refundPayment) {
                    $refundPayment->update(
                        $this->paymentFinanceService->applyRefundPolicy($refundPayment, $order, 'order_rejected')
                    );
                }

                $this->refreshProviderAvailability($order->provider_id);

                app(N8nNotificationService::class)->dispatch('order_rejected', [
                    'order_id' => $order->id,
                    'order_code' => $order->order_code,
                    'provider_id' => $order->provider_id,
                    'status' => $order->status,
                    'refund_count' => $refundPayments->count(),
                ]);

                return $this->success(['status' => $order->status], 'Order rejected');
            });
        } catch (\Throwable $e) {
            return $this->internalServerError('Failed to update order status');
        }
    }

    /**
     * Provider mulai pekerjaan
     */
    public function startWork(Request $request, $orderId)
    {
        $user = Auth::user();

        $order = Order::with('payments')->find($orderId);

        if (!$order) {
            return $this->notFound('Order not found');
        }

        if (!$this->isAssignedToCurrentProvider($order->provider_id, $user)) {
            return $this->forbidden('Unauthorized');
        }

        if ($order->status !== 'ACCEPTED') {
            return $this->conflict('Work can only be started after the order is accepted');
        }

        $dpPayment = $order->payments()->where('payment_type', 'DP')->first();
        if (!$dpPayment || $dpPayment->status !== 'PAID') {
            return $this->validationError([
                'dp_payment' => ['DP payment must be paid before work can start'],
            ]);
        }

        try {
            DB::transaction(function () use ($order, $user) {
                $oldStatus = $order->status;
                $order->update(['status' => 'IN_PROGRESS']);
                OrderStatusLog::create([
                    'order_id' => $order->id,
                    'old_status' => $oldStatus,
                    'new_status' => 'IN_PROGRESS',
                    'changed_by' => $user->id,
                ]);
            });

            app(N8nNotificationService::class)->dispatch('work_started', [
                'order_id' => $order->id,
                'order_code' => $order->order_code,
                'provider_id' => $order->provider_id,
                'status' => $order->status,
            ]);

            return $this->success(['status' => $order->status], 'Work started');
        } catch (\Throwable $e) {
            return $this->internalServerError('Failed to start work');
        }
    }

    /**
     * Provider selesaikan pekerjaan
     */
    public function completeOrder(CompleteOrderRequest $request, $orderId)
    {
        $user = Auth::user();

        $order = Order::with('payments')->find($orderId);

        if (!$order) {
            return $this->notFound('Order not found');
        }

        if (!$this->isAssignedToCurrentProvider($order->provider_id, $user)) {
            return $this->forbidden('Unauthorized');
        }

        if ($order->status !== 'IN_PROGRESS') {
            return $this->conflict('Order can only be completed after work has started');
        }

        $validated = $request->validated();

        if ($validated['final_price'] < $order->estimated_price) {
            return $this->validationError([
                'final_price' => ['Final price must be at least equal to estimated price.'],
            ]);
        }

        try {
            $result = DB::transaction(function () use ($order, $validated, $user, $request) {
                $oldStatus = $order->status;
                $order->update([
                    'status' => 'COMPLETED',
                    'final_price' => $validated['final_price'],
                ]);

                OrderStatusLog::create([
                    'order_id' => $order->id,
                    'old_status' => $oldStatus,
                    'new_status' => 'COMPLETED',
                    'changed_by' => $user->id,
                ]);

                // Buat/refresh record approval harga akhir. Payment FINAL baru boleh dibuat
                // setelah customer menyetujui (sesuai requirement).
                \App\Models\FinalPriceApproval::updateOrCreate(
                    [
                        'order_id' => $order->id,
                    ],
                    [
                        'proposed_final_price' => $validated['final_price'],
                        'approval_status' => 'PENDING',
                        'approved_by' => null,
                    ]
                );

                \App\Models\FinalPriceLog::create([
                    'order_id' => $order->id,
                    'proposed_final_price' => $validated['final_price'],
                    'action' => 'SUBMIT',
                    'submitted_by' => $user->id,
                ]);

                $dpPayment = $order->payments()->where('payment_type', 'DP')->first();
                $dpAmount = $dpPayment?->amount ?? 0;
                $finalAmount = max(0, $validated['final_price'] - $dpAmount);

                return ['order' => $order, 'finalAmount' => $finalAmount];
            });

            $order = $result['order'];
            $finalAmount = $result['finalAmount'];

            app(N8nNotificationService::class)->dispatch('order_completed', [
                'order_id' => $order->id,
                'order_code' => $order->order_code,
                'provider_id' => $order->provider_id,
                'final_price' => $validated['final_price'],
                'final_amount' => $finalAmount,
                'status' => $order->status,
            ]);

            $this->refreshProviderAvailability($order->provider_id);

            return $this->success([
                'status' => $order->status,
                'final_amount' => $finalAmount,
            ], 'Order completed');
        } catch (\Throwable $e) {
            Log::error('Complete order error: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return $this->internalServerError('Failed to complete order');
        }
    }

    private function storeReportFiles(Request $request, Order $order, string $field, string $purpose): void
    {
        if (!$request->hasFile($field)) {
            return;
        }

        foreach ($request->file($field) as $file) {
            try {
                /** @var UploadedFile $file */
                $ext = $file->getClientOriginalExtension() ?: 'jpg';
                $fileName = sprintf('%s_%s_%s.%s', $order->id, strtolower($purpose), uniqid(), $ext);
                $path = $file->storeAs('orders/reports', $fileName, 'public');
                OrderAttachment::create([
                    'order_id' => $order->id,
                    'file_url' => $path,
                    'file_type' => $file->getClientMimeType() ?? 'image/jpeg',
                    'purpose' => $purpose,
                ]);
            } catch (\Throwable $e) {
                Log::warning('Failed to store provider report file: ' . $e->getMessage());
            }
        }
    }

    private function refreshProviderAvailability(int $providerId): void
    {
        $providerProfile = $this->findProviderProfileByIdentifier($providerId);
        if (!$providerProfile) {
            return;
        }

        $providerIds = array_values(array_unique([
            (int) $providerProfile->user_id,
            (int) $providerProfile->id,
        ]));

        $hasActiveOrder = Order::whereIn('provider_id', $providerIds)
            ->whereIn('status', ['ACCEPTED', 'IN_PROGRESS'])
            ->exists();

        $providerProfile?->update([
            'availability_status' => $hasActiveOrder ? 'BUSY' : 'AVAILABLE',
        ]);
    }

    private function findProviderProfileByIdentifier(int $providerId): ?\App\Models\ProviderProfile
    {
        $provider = User::where('id', $providerId)->where('role', 'PROVIDER')->first();
        if ($provider?->providerProfile) {
            return $provider->providerProfile;
        }

        return \App\Models\ProviderProfile::find($providerId);
    }

    private function resolveProviderAssignment(int $providerIdentifier): array
    {
        $provider = User::where('id', $providerIdentifier)->where('role', 'PROVIDER')->first();
        if ($provider?->providerProfile) {
            return [$provider, $provider->providerProfile];
        }

        $providerProfile = \App\Models\ProviderProfile::with('user')->find($providerIdentifier);
        if ($providerProfile?->user && $providerProfile->user->role === 'PROVIDER') {
            return [$providerProfile->user, $providerProfile];
        }

        throw new ModelNotFoundException('Provider not found');
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

    /**
     * Customer batalkan order
     */
    public function cancelOrder(Request $request, $orderId)
    {
        $user = Auth::user();


        $order = Order::with('payments')->find($orderId);

        if (!$order) {
            return $this->notFound('Order not found');
        }

        if ($order->customer_id !== $user->id) {
            return $this->forbidden('Unauthorized');
        }

        $cancellableStatuses = ['CREATED', 'ACCEPTED', 'IN_PROGRESS'];
        if (!in_array($order->status, $cancellableStatuses)) {
            return $this->conflict('Order tidak bisa dibatalkan pada status: ' . $order->status);
        }

        $request->validate([
            'reason' => 'nullable|string|max:500',
        ]);

        try {
            $result = DB::transaction(function () use ($order, $request, $user) {
                $oldStatus = $order->status;
                $order->update(['status' => 'CANCELLED']);

                OrderStatusLog::create([
                    'order_id' => $order->id,
                    'old_status' => $oldStatus,
                    'new_status' => 'CANCELLED',
                    'changed_by' => $user->id,
                    'reason' => $request->input('reason', 'Dibatalkan oleh customer'),
                ]);

                // Refund DP if already paid
                $refundedPayments = [];
                $dpPayment = $order->payments()->where('payment_type', 'DP')->where('status', 'PAID')->first();
                if ($dpPayment) {
                    $dpPayment->update(
                        $this->paymentFinanceService->applyRefundPolicy($dpPayment, $order, 'customer_cancelled')
                    );
                    $refundedPayments[] = $dpPayment;
                }

                return ['refund_count' => count($refundedPayments)];
            });

            app(N8nNotificationService::class)->dispatch('order_cancelled', [
                'order_id' => $order->id,
                'order_code' => $order->order_code,
                'customer_id' => $order->customer_id,
                'provider_id' => $order->provider_id,
                'reason' => $request->input('reason', 'Dibatalkan oleh customer'),
                'refund_count' => $result['refund_count'],
            ]);

            $this->refreshProviderAvailability($order->provider_id);

            return $this->success(['status' => 'CANCELLED'], 'Order berhasil dibatalkan');
        } catch (\Throwable $e) {
            Log::error('Cancel order error: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return $this->internalServerError('Failed to cancel order');
        }
    }
}
