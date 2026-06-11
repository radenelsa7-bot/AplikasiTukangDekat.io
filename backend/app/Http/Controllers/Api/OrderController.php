<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use App\Services\PaymentFinanceService;
use App\Services\N8nNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
  public function __construct(
    private readonly PaymentFinanceService $paymentFinanceService,
  ) {}

  /**
   * Buat order baru
   */
  public function createOrder(Request $request)
  {
    $user = Auth::user();

    if ($user->role !== 'CUSTOMER') {
      return response()->json([
        'message' => 'only customer can create order',
      ], 403);
    }

    $validated = $request->validate([
      'provider_id' => 'required|exists:users,id',
      'provider_service_id' => 'nullable|exists:provider_services,id',
      'category_id' => 'required|exists:service_categories,id',
      'schedule_at' => 'required|date_format:Y-m-d H:i:s|after:now',
      'address' => 'required|string|max:500',
      'notes' => 'nullable|string|max:1000',
      'estimated_price' => 'required|integer|min:1000|max:100000000',
    ]);

    // Validasi provider adalah user dengan role PROVIDER
    $provider = User::where('id', $validated['provider_id'])
      ->where('role', 'PROVIDER')
      ->firstOrFail();

    // Gunakan transaction untuk atomicity
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

        // Buat payment DP (50%)
        $dpAmount = intval($validated['estimated_price'] * 0.5);
        Payment::create([
          'order_id' => $order->id,
          'payment_type' => 'DP',
          'amount' => $dpAmount,
          'status' => 'UNPAID',
        ]);

        return [
          'order' => $order,
          'dp_amount' => $dpAmount,
        ];
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

      return response()->json([
        'message' => 'order created',
        'data' => [
          'order_id' => $order->id,
          'order_code' => $order->order_code,
          'status' => $order->status,
          'dp_amount' => $dpAmount,
        ],
      ], 201);
    } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
      return response()->json([
        'message' => 'provider not found or invalid',
      ], 422);
    } catch (\Exception $e) {
      return response()->json([
        'message' => 'failed to create order',
        'error' => config('app.debug') ? $e->getMessage() : 'An error occurred',
      ], 500);
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
      return response()->json([
        'message' => 'order not found',
      ], 404);
    }

    return response()->json([
      'data' => $order,
    ], 200);
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
      return response()->json([
        'message' => 'unauthorized',
      ], 403);
    }

    return response()->json([
      'data' => $orders,
    ], 200);
  }

  /**
   * Provider terima/tolak order
   */
  public function respondToOrder(Request $request, $orderId)
  {
    $user = Auth::user();

    if ($user->role !== 'PROVIDER') {
      return response()->json([
        'message' => 'only provider can respond to order',
      ], 403);
    }

    $order = Order::find($orderId);

    if (!$order) {
      return response()->json([
        'message' => 'order not found',
      ], 404);
    }

    if ($order->provider_id !== $user->id) {
      return response()->json([
        'message' => 'unauthorized',
      ], 403);
    }

    $validated = $request->validate([
      'action' => 'required|in:accept,reject',
    ]);

    if ($validated['action'] === 'accept') {
      $order->update(['status' => 'ACCEPTED']);

      app(N8nNotificationService::class)->dispatch('order_accepted', [
        'order_id' => $order->id,
        'order_code' => $order->order_code,
        'provider_id' => $order->provider_id,
        'status' => $order->status,
      ]);

      return response()->json([
        'message' => 'order accepted',
        'data' => ['status' => $order->status],
      ], 200);
    } else {
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

      return response()->json([
        'message' => 'order rejected',
        'data' => ['status' => $order->status],
      ], 200);
    }
  }

  /**
   * Provider mulai pekerjaan (hanya jika DP sudah dibayar)
   */
  public function startWork(Request $request, $orderId)
  {
    $user = Auth::user();

    if ($user->role !== 'PROVIDER') {
      return response()->json([
        'message' => 'only provider can start work',
      ], 403);
    }

    $order = Order::with('payments')->find($orderId);

    if (!$order) {
      return response()->json([
        'message' => 'order not found',
      ], 404);
    }

    if ($order->provider_id !== $user->id) {
      return response()->json([
        'message' => 'unauthorized',
      ], 403);
    }

    $dpPayment = $order->payments()->where('payment_type', 'DP')->first();
    if (!$dpPayment || $dpPayment->status !== 'PAID') {
      return response()->json([
        'message' => 'dp payment must be paid before work can start',
      ], 422);
    }

    $order->update(['status' => 'IN_PROGRESS']);

    app(N8nNotificationService::class)->dispatch('work_started', [
      'order_id' => $order->id,
      'order_code' => $order->order_code,
      'provider_id' => $order->provider_id,
      'status' => $order->status,
    ]);

    return response()->json([
      'message' => 'work started',
      'data' => ['status' => $order->status],
    ], 200);
  }

  /**
   * Provider selesaikan pekerjaan
   */
  public function completeOrder(Request $request, $orderId)
  {
    $user = Auth::user();

    if ($user->role !== 'PROVIDER') {
      return response()->json([
        'message' => 'only provider can complete order',
      ], 403);
    }

    $order = Order::find($orderId);

    if (!$order) {
      return response()->json([
        'message' => 'order not found',
      ], 404);
    }

    if ($order->provider_id !== $user->id) {
      return response()->json([
        'message' => 'unauthorized',
      ], 403);
    }

    $validated = $request->validate([
      'final_price' => 'required|integer|min:1000|max:100000000',
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
    } catch (\Exception $e) {
      return response()->json([
        'message' => 'failed to complete order',
        'error' => config('app.debug') ? $e->getMessage() : 'An error occurred',
      ], 500);
    }
  }
}
