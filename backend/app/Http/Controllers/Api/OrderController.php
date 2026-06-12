<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Order\CompleteOrderRequest;
use App\Http\Requests\Order\CreateOrderRequest;
use App\Http\Requests\Order\RespondOrderRequest;
use App\Models\Order;
use App\Models\Payment;
use App\Services\PaymentFinanceService;
use App\Services\N8nNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class OrderController extends Controller
{
  public function __construct(
    private readonly PaymentFinanceService $paymentFinanceService,
  ) {}

  /**
   * Buat order baru
   */
  public function createOrder(CreateOrderRequest $request)
  {
    $user = Auth::user();

    if ($user->role !== 'CUSTOMER') {
      return $this->forbiddenResponse('only customer can create order');
    }

    $validated = $request->validated();

    $order = Order::create([
      'order_code' => Order::generateCode(),
      'customer_id' => $user->id,
      'provider_id' => $validated['provider_id'],
      'category_id' => $validated['category_id'],
      'provider_service_id' => $validated['provider_service_id'] ?? null,
      'schedule_at' => $validated['schedule_at'],
      'address' => $validated['address'],
      'notes' => $validated['notes'] ?? null,
      'estimated_price' => $validated['estimated_price'],
      'status' => 'CREATED',
    ]);

    // Buat payment DP (50%)
    $dpAmount = intval($validated['estimated_price'] * 0.5);
    Payment::create([
      'order_id' => $order->id,
      'payment_type' => 'DP',
      'amount' => $dpAmount,
      'status' => 'UNPAID',
    ]);

    $provider = $order->provider;

    app(N8nNotificationService::class)->dispatch('order_created', [
      'order_id' => $order->id,
      'order_code' => $order->order_code,
      'customer_id' => $order->customer_id,
      'provider_id' => $order->provider_id,
      'customer_name' => $user->name,
      'customer_email' => $user->email,
      'customer_phone' => $user->phone,
      'provider_name' => $provider?->name,
      'provider_email' => $provider?->email,
      'provider_phone' => $provider?->phone,
      'estimated_price' => $order->estimated_price,
      'dp_amount' => $dpAmount,
      'status' => $order->status,
    ]);

    return $this->createdResponse([
      'order_id' => $order->id,
      'order_code' => $order->order_code,
      'status' => $order->status,
      'dp_amount' => $dpAmount,
    ], 'order created');
  }

  /**
   * Get order berdasarkan ID
   */
  public function getOrder($orderId)
  {
    $order = Order::with(['customer', 'provider', 'payments'])
      ->find($orderId);

    if (!$order) {
      return $this->notFoundResponse('order not found');
    }

    return $this->successResponse(['order' => $order], 'ok', 200);
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
        ->latest()
        ->get();
    } else if ($user->role === 'PROVIDER') {
      $orders = Order::where('provider_id', $user->id)
        ->with(['customer', 'payments'])
        ->latest()
        ->get();
    } else {
      return $this->forbiddenResponse('unauthorized');
    }

    return $this->successResponse(['orders' => $orders], 'ok', 200);
  }

  /**
   * Provider terima/tolak order
   */
  public function respondToOrder(RespondOrderRequest $request, $orderId)
  {
    $user = Auth::user();

    if ($user->role !== 'PROVIDER') {
      return $this->forbiddenResponse('only provider can respond to order');
    }

    $order = Order::find($orderId);

    if (!$order) {
      return $this->notFoundResponse('order not found');
    }

    if ($order->provider_id !== $user->id) {
      return $this->forbiddenResponse('unauthorized');
    }

    $validated = $request->validated();

    if ($validated['action'] === 'accept') {
      $order->update(['status' => 'ACCEPTED']);

      app(N8nNotificationService::class)->dispatch('order_accepted', [
        'order_id' => $order->id,
        'order_code' => $order->order_code,
        'provider_id' => $order->provider_id,
        'provider_name' => $user->name,
        'provider_email' => $user->email,
        'customer_name' => $order->customer?->name,
        'customer_email' => $order->customer?->email,
        'status' => $order->status,
      ]);

      return $this->successResponse(['status' => $order->status], 'order accepted', 200);
    }

    $order->update(['status' => 'CANCELLED']);

    $refundPayments = $order->payments()
      ->where('payment_type', 'DP')
      ->where('status', 'PAID')
      ->get();

    foreach ($refundPayments as $refundPayment) {
      $refundPayment->update(
        $this->paymentFinanceService->applyRefundPolicy($refundPayment, $order, 'order_rejected')
      );
    }

    app(N8nNotificationService::class)->dispatch('order_rejected', [
      'order_id' => $order->id,
      'order_code' => $order->order_code,
      'provider_id' => $order->provider_id,
      'provider_name' => $user->name,
      'provider_email' => $user->email,
      'customer_name' => $order->customer?->name,
      'customer_email' => $order->customer?->email,
      'status' => $order->status,
      'refund_count' => $refundPayments->count(),
    ]);

    return $this->successResponse(['status' => $order->status], 'order rejected', 200);
  }

  /**
   * Provider mulai pekerjaan (hanya jika DP sudah dibayar)
   */
  public function startWork(Request $request, $orderId)
  {
    $user = Auth::user();

    if ($user->role !== 'PROVIDER') {
      return $this->forbiddenResponse('only provider can start work');
    }

    $order = Order::with('payments')->find($orderId);

    if (!$order) {
      return $this->notFoundResponse('order not found');
    }

    if ($order->provider_id !== $user->id) {
      return $this->forbiddenResponse('unauthorized');
    }

    $dpPayment = $order->payments()->where('payment_type', 'DP')->first();
    if (!$dpPayment || $dpPayment->status !== 'PAID') {
      return $this->errorResponse('dp payment must be paid before work can start', 422);
    }

    $order->update(['status' => 'IN_PROGRESS']);

    app(N8nNotificationService::class)->dispatch('work_started', [
      'order_id' => $order->id,
      'order_code' => $order->order_code,
      'provider_id' => $order->provider_id,
      'status' => $order->status,
    ]);

    return $this->successResponse(['status' => $order->status], 'work started', 200);
  }

  /**
   * Provider selesaikan pekerjaan
   */
  public function completeOrder(CompleteOrderRequest $request, $orderId)
  {
    $user = Auth::user();

    if ($user->role !== 'PROVIDER') {
      return $this->forbiddenResponse('only provider can complete order');
    }

    $order = Order::find($orderId);

    if (!$order) {
      return $this->notFoundResponse('order not found');
    }

    if ($order->provider_id !== $user->id) {
      return $this->forbiddenResponse('unauthorized');
    }

    $validated = $request->validated();

    $order->update([
      'status' => 'COMPLETED',
      'final_price' => $validated['final_price'],
    ]);

    // Buat payment final
    $finalAmount = $validated['final_price'] - ($order->payments()->where('payment_type', 'DP')->first()->amount ?? 0);
    Payment::create([
      'order_id' => $order->id,
      'payment_type' => 'FINAL',
      'amount' => $finalAmount,
      'status' => 'UNPAID',
    ]);

    app(N8nNotificationService::class)->dispatch('order_completed', [
      'order_id' => $order->id,
      'order_code' => $order->order_code,
      'provider_id' => $order->provider_id,
      'provider_name' => $user->name,
      'provider_email' => $user->email,
      'customer_name' => $order->customer?->name,
      'customer_email' => $order->customer?->email,
      'final_price' => $validated['final_price'],
      'final_amount' => $finalAmount,
      'remaining_amount' => $finalAmount,
      'status' => $order->status,
    ]);

    return $this->successResponse([
      'status' => $order->status,
      'final_amount' => $finalAmount,
    ], 'order completed', 200);
  }
}
