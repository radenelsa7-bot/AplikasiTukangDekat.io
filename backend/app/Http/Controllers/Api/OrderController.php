<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Order\CompleteOrderRequest;
use App\Http\Requests\Order\CreateOrderRequest;
use App\Http\Requests\Order\RespondOrderRequest;
use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
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
use App\Http\Requests\Order\CreateOrderRequest;
use App\Http\Requests\Order\RespondToOrderRequest;
use App\Http\Requests\Order\CompleteOrderRequest;
use Illuminate\Support\Facades\Log;

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

    if ($user->role !== 'CUSTOMER') {
      return $this->forbidden('Only customers can create orders');
    }

    try {
      $validated = $request->validated();

      // Validasi provider adalah user dengan role PROVIDER
      $provider = User::where('id', $validated['provider_id'])
        ->where('role', 'PROVIDER')
        ->firstOrFail();

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

        // Buat payment DP (50%)
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
    $user = Auth::user();
    $order = Order::with(['customer', 'provider', 'payments'])
      ->find($orderId);

    if (!$order) {
      return $this->notFound('Order not found');
    }

    return $this->success($order, 'Order retrieved');
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
      return $this->forbidden('Unauthorized');
    }

    return $this->success($orders, 'Orders retrieved');
      return $this->forbiddenResponse('unauthorized');
    }

    return $this->successResponse(['orders' => $orders], 'ok', 200);
  }

  /**
   * Provider terima/tolak order
   */
  public function respondToOrder(RespondToOrderRequest $request, $orderId)
  {
    $user = Auth::user();

    $order = Order::find($orderId);

    if (!$order) {
      return $this->notFound('Order not found');
    }

    if ($order->provider_id !== $user->id) {
      return $this->forbidden('Unauthorized');
    }

    $validated = $request->validated();

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
      return $this->validationError(['dp_payment' => ['DP payment must be paid before work can start']]);
      return $this->errorResponse('dp payment must be paid before work can start', 422);
    }

    $order->update(['status' => 'IN_PROGRESS']);

    app(N8nNotificationService::class)->dispatch('work_started', [
      'order_id' => $order->id,
      'order_code' => $order->order_code,
      'provider_id' => $order->provider_id,
      'status' => $order->status,
    ]);

    return $this->success(['status' => $order->status], 'Work started');
    return $this->successResponse(['status' => $order->status], 'work started', 200);
  }

  /**
   * Provider selesaikan pekerjaan
   */
  public function completeOrder(CompleteOrderRequest $request, $orderId)
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

    $validated = $request->validated();

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
    if ($user->role !== 'PROVIDER') {
      return $this->forbiddenResponse('only provider can complete order');
    }

    $order = Order::with('payments')->find($orderId);

    if (!$order) {
      return $this->notFoundResponse('order not found');
    }

    if ($order->provider_id !== $user->id) {
      return $this->forbiddenResponse('unauthorized');
    }

    $validated = $request->validate([
      'final_price' => 'required|integer|min:1',
    ]);

    // Validasi final_price >= estimated_price
    if ($validated['final_price'] < $order->estimated_price) {
      return response()->json([
        'message' => 'final price must be at least equal to estimated price',
      ], 422);
    }

    try {
      $result = DB::transaction(function () use ($order, $validated) {
        $order->update([
          'status' => 'COMPLETED',
          'final_price' => $validated['final_price'],
        ]);

        // Buat payment final
        $dpPayment = $order->payments()->where('payment_type', 'DP')->first();
        $dpAmount = $dpPayment->amount ?? 0;
        $finalAmount = max(0, $validated['final_price'] - $dpAmount);

        Payment::create([
          'order_id' => $order->id,
          'payment_type' => 'FINAL',
          'amount' => $finalAmount,
          'status' => 'UNPAID',
        ]);

        return [
          'order' => $order,
          'final_amount' => $finalAmount,
        ];
      });

      $order = $result['order'];
      $finalAmount = $result['final_amount'];

    app(N8nNotificationService::class)->dispatch('order_completed', [
      'order_id' => $order->id,
      'order_code' => $order->order_code,
      'provider_id' => $order->provider_id,
      'final_price' => $validated['final_price'],
      'final_amount' => $finalAmount,
      'status' => $order->status,
    ]);

    return response()->json([
      'message' => 'order completed',
      'data' => [
        'status' => $order->status,
        'final_amount' => $finalAmount,
      ],
    ], 200);
    } catch (\Throwable $e) {
      return $this->errorResponse('internal server error', 500);
    }
  }
}
