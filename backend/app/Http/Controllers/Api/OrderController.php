<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Payment;
use App\Services\PaymentFinanceService;
use App\Services\N8nNotificationService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Database\QueryException;
use Illuminate\Database\Transactions\TransactionException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use App\Traits\ApiResponse;

class OrderController extends Controller
{
  use ApiResponse;
  public function __construct(
    private readonly PaymentFinanceService $paymentFinanceService,
  ) {}

  /**
   * Buat order baru
   */
  public function createOrder(Request $request)
  {
    $user = Auth::user();

    // Route enforces role.customer, but double-check
    if ($user->role !== 'CUSTOMER') {
      return $this->forbidden('Only customers can create orders');
    }

    $validated = $request->validate([
      'provider_id' => ['required', 'integer', Rule::exists('users', 'id')->where('role', 'PROVIDER')],
      'provider_service_id' => 'nullable|exists:provider_services,id',
      'category_id' => 'required|exists:service_categories,id',
      'schedule_at' => 'required|date_format:Y-m-d H:i:s',
      'address' => 'required|string',
      'notes' => 'nullable|string',
      'estimated_price' => 'required|integer|min:1',
    ]);

    try {
      $result = DB::transaction(function () use ($validated, $user) {
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

        $dpAmount = intval($validated['estimated_price'] * 0.5);
        Payment::create([
          'order_id' => $order->id,
          'payment_type' => 'DP',
          'amount' => $dpAmount,
          'status' => 'UNPAID',
        ]);

        return ['order' => $order, 'dp_amount' => $dpAmount];
      });

      $order = $result['order'];
      $dpAmount = $result['dp_amount'];

      app(N8nNotificationService::class)->dispatch('order_created', [
        'order_id' => $order->id,
        'order_code' => $order->order_code,
        'customer_id' => $order->customer_id,
        'provider_id' => $order->provider_id,
        'estimated_price' => $order->estimated_price,
        'dp_amount' => $dpAmount,
        'status' => $order->status,
      ]);

      return $this->success([
        'order_id' => $order->id,
        'order_code' => $order->order_code,
        'status' => $order->status,
        'dp_amount' => $dpAmount,
      ], 'Order created', 201);
    } catch (\Throwable $e) {
      return $this->internalServerError('Failed to create order');
    }
  }

  /**
   * Get order berdasarkan ID
   */
  public function getOrder($orderId)
  {
    $order = Order::with(['customer', 'provider', 'payments'])
      ->find($orderId);

    if (!$order) {
      return $this->notFound('Order not found');
    }

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
        ->latest()
        ->get();
    } else if ($user->role === 'PROVIDER') {
      $orders = Order::where('provider_id', $user->id)
        ->with(['customer', 'payments'])
        ->latest()
        ->get();
    } else {
      return $this->forbidden('Unauthorized');
    }

    return $this->success($orders, 'Orders retrieved');
  }

  /**
   * Provider terima/tolak order
   */
  public function respondToOrder(Request $request, $orderId)
  {
    $user = Auth::user();

    $order = Order::find($orderId);

    if (!$order) {
      return $this->notFound('Order not found');
    }

    if ($order->provider_id !== $user->id) {
      return $this->forbidden('Unauthorized');
    }

    $validated = $request->validate([
      'action' => 'required|in:accept,reject',
    ]);

    if ($order->status !== 'CREATED') {
      return $this->conflict('Order cannot be responded to in its current status');
    }

    try {
      return DB::transaction(function () use ($order, $validated) {
        if ($validated['action'] === 'accept') {
          $order->update(['status' => 'ACCEPTED']);

          app(N8nNotificationService::class)->dispatch('order_accepted', [
            'order_id' => $order->id,
            'order_code' => $order->order_code,
            'provider_id' => $order->provider_id,
            'status' => $order->status,
          ]);

          return $this->success(['status' => $order->status], 'Order accepted');
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

    $order = Order::find($orderId);

    if (!$order) {
      return $this->notFound('Order not found');
    }

    if ($order->provider_id !== $user->id) {
      return $this->forbidden('Unauthorized');
    }

    if ($order->status !== 'ACCEPTED') {
      return $this->conflict('Work can only be started after the order is accepted');
    }

    $dpPayment = $order->payments()->where('payment_type', 'DP')->first();
    if (!$dpPayment || $dpPayment->status !== 'PAID') {
      return $this->validationError(['dp_payment' => ['DP payment must be paid before work can start']]);
    }

    $order->update(['status' => 'IN_PROGRESS']);

    app(N8nNotificationService::class)->dispatch('work_started', [
      'order_id' => $order->id,
      'order_code' => $order->order_code,
      'provider_id' => $order->provider_id,
      'status' => $order->status,
    ]);

    return $this->success(['status' => $order->status], 'Work started');
  }

  /**
   * Provider selesaikan pekerjaan
   */
  public function completeOrder(Request $request, $orderId)
  {
    $user = Auth::user();

    $order = Order::find($orderId);

    if (!$order) {
      return $this->notFound('Order not found');
    }

    if ($order->provider_id !== $user->id) {
      return $this->forbidden('Unauthorized');
    }

    if ($order->status !== 'IN_PROGRESS') {
      return $this->conflict('Order can only be completed after work has started');
    }

    $validated = $request->validate([
      'final_price' => 'required|integer|min:1',
    ]);

    try {
      return DB::transaction(function () use ($order, $validated) {
        $order->update([
          'status' => 'COMPLETED',
          'final_price' => $validated['final_price'],
        ]);

        $dpPayment = $order->payments()->where('payment_type', 'DP')->first();
        $dpAmount = $dpPayment?->amount ?? 0;
        $finalAmount = max(0, $validated['final_price'] - $dpAmount);

        if ($finalAmount > 0) {
          Payment::create([
            'order_id' => $order->id,
            'payment_type' => 'FINAL',
            'amount' => $finalAmount,
            'status' => 'UNPAID',
          ]);
        }

        app(N8nNotificationService::class)->dispatch('order_completed', [
          'order_id' => $order->id,
          'order_code' => $order->order_code,
          'provider_id' => $order->provider_id,
          'final_price' => $validated['final_price'],
          'final_amount' => $finalAmount,
          'status' => $order->status,
        ]);

        return $this->success([
          'status' => $order->status,
          'final_amount' => $finalAmount,
        ], 'Order completed');
      });
    } catch (\Throwable $e) {
      return $this->internalServerError('Failed to complete order');
    }
  }
}
