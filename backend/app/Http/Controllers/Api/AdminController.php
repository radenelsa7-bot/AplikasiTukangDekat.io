<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateVerificationRequest;
use App\Models\Order;
use App\Models\Payment;
use App\Models\ProviderProfile;
use App\Models\ServiceCategory;
use App\Models\User;
use App\Services\N8nNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Traits\ApiResponse;

class AdminController extends Controller
{
    use ApiResponse;

    // ===== DASHBOARD =====

    public function dashboard()
    {
        $totalUsers = User::count();
        $totalCustomers = User::where('role', 'CUSTOMER')->count();
        $totalProviders = User::where('role', 'PROVIDER')->count();
        $pendingProviders = ProviderProfile::where('is_verified', false)->count();
        $totalOrders = Order::count();
        $activeOrders = Order::whereIn('status', ['CREATED', 'ACCEPTED', 'IN_PROGRESS'])->count();
        $completedOrders = Order::whereIn('status', ['COMPLETED', 'CLOSED'])->count();
        $totalRevenue = Payment::where('status', 'PAID')->sum('amount');
        $totalCategories = ServiceCategory::count();

        $recentOrders = Order::with(['customer', 'provider'])
            ->latest()
            ->take(5)
            ->get()
            ->map(fn($o) => [
                'id' => $o->id,
                'order_code' => $o->order_code,
                'customer_name' => $o->customer?->name,
                'provider_name' => $o->provider?->name,
                'status' => $o->status,
                'estimated_price' => $o->estimated_price,
                'created_at' => $o->created_at?->toDateTimeString(),
            ]);

        $recentPayments = Payment::with(['order.customer'])
            ->where('status', 'PAID')
            ->latest('paid_at')
            ->take(5)
            ->get()
            ->map(fn($p) => [
                'id' => $p->id,
                'order_id' => $p->order_id,
                'payment_type' => $p->payment_type,
                'amount' => $p->amount,
                'customer_name' => $p->order?->customer?->name,
                'paid_at' => $p->paid_at?->toDateTimeString(),
            ]);

        return $this->success([
            'stats' => [
                'total_users' => $totalUsers,
                'total_customers' => $totalCustomers,
                'total_providers' => $totalProviders,
                'pending_providers' => $pendingProviders,
                'total_orders' => $totalOrders,
                'active_orders' => $activeOrders,
                'completed_orders' => $completedOrders,
                'total_revenue' => $totalRevenue,
                'total_categories' => $totalCategories,
            ],
            'recent_orders' => $recentOrders,
            'recent_payments' => $recentPayments,
        ], 'Dashboard data retrieved');
    }

    // ===== PROVIDER MANAGEMENT =====

    public function getPendingProviders(Request $request)
    {
        $providers = ProviderProfile::with(['user', 'services.category'])
            ->where('is_verified', false)
            ->latest()
            ->get();

        return $this->success($providers, 'Pending providers');
    }

    public function getAllProviders(Request $request)
    {
        $query = ProviderProfile::with(['user', 'services.category']);

        if ($request->has('is_verified')) {
            $query->where('is_verified', filter_var($request->query('is_verified'), FILTER_VALIDATE_BOOLEAN));
        }

        $providers = $query->latest()->get();
        return $this->success($providers, 'All providers');
    }

    public function updateVerification(UpdateVerificationRequest $request, $providerId)
    {
        $validated = $request->validated();
        $provider = ProviderProfile::with('user')->find($providerId);

        if (!$provider) {
            return $this->notFound('Provider not found');
        }

        $provider->update([
            'is_verified' => $validated['is_verified'],
        ]);

        app(N8nNotificationService::class)->dispatch(
            $validated['is_verified'] ? 'provider_verified' : 'provider_unverified',
            [
                'provider_id' => $provider->id,
                'user_id' => $provider->user_id,
                'business_name' => $provider->business_name,
                'area' => $provider->area,
                'is_verified' => $provider->is_verified,
            ]
        );

        return $this->success($provider, 'Verification updated');
    }

    public function disableProvider(Request $request, $providerId)
    {
        $request->validate(['reason' => 'nullable|string|max:500']);

        $provider = User::where('id', $providerId)->where('role', 'PROVIDER')->first();
        if (!$provider) {
            return $this->notFound('Provider not found');
        }

        if ($provider->status === 'SUSPENDED') {
            return $this->error('Provider is already disabled', 409);
        }

        $provider->update(['status' => 'SUSPENDED']);

        $profile = ProviderProfile::where('user_id', $providerId)->first();
        if ($profile) {
            $profile->update(['is_verified' => false]);
        }

        app(N8nNotificationService::class)->dispatch('provider_disabled', [
            'provider_id' => $providerId,
            'provider_name' => $provider->name,
            'reason' => $request->input('reason', 'Policy violation'),
        ]);

        return $this->success(['provider_id' => $provider->id, 'status' => $provider->status], 'Provider disabled');
    }

    public function enableProvider(Request $request, $providerId)
    {
        $provider = User::where('id', $providerId)->where('role', 'PROVIDER')->first();
        if (!$provider) {
            return $this->notFound('Provider not found');
        }

        if ($provider->status === 'ACTIVE') {
            return $this->error('Provider is already active', 409);
        }

        $provider->update(['status' => 'ACTIVE']);

        app(N8nNotificationService::class)->dispatch('provider_enabled', [
            'provider_id' => $providerId,
            'provider_name' => $provider->name,
        ]);

        return $this->success(['provider_id' => $provider->id, 'status' => $provider->status], 'Provider enabled');
    }

    // ===== CATEGORY MANAGEMENT =====

    public function getCategories()
    {
        $categories = ServiceCategory::withCount('providerServices')->get();
        return $this->success($categories, 'Categories retrieved');
    }

    public function createCategory(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100|unique:service_categories,name',
            'description' => 'nullable|string|max:500',
            'is_active' => 'boolean',
        ]);

        $category = ServiceCategory::create([
            'name' => $validated['name'],
            'description' => $validated['description'] ?? '',
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return $this->success($category, 'Category created', 201);
    }

    public function updateCategory(Request $request, $categoryId)
    {
        $category = ServiceCategory::find($categoryId);
        if (!$category) {
            return $this->notFound('Category not found');
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:100|unique:service_categories,name,' . $categoryId,
            'description' => 'nullable|string|max:500',
            'is_active' => 'sometimes|boolean',
        ]);

        $category->update($validated);
        return $this->success($category, 'Category updated');
    }

    public function deleteCategory($categoryId)
    {
        $category = ServiceCategory::find($categoryId);
        if (!$category) {
            return $this->notFound('Category not found');
        }

        $serviceCount = $category->providerServices()->count();
        if ($serviceCount > 0) {
            return $this->error("Cannot delete category with $serviceCount active services. Deactivate it instead.", 409);
        }

        $category->delete();
        return $this->success(null, 'Category deleted');
    }

    // ===== USER MANAGEMENT =====

    public function getUsers(Request $request)
    {
        $query = User::query();

        if ($request->has('role')) {
            $query->where('role', strtoupper($request->query('role')));
        }

        if ($request->has('status')) {
            $query->where('status', strtoupper($request->query('status')));
        }

        if ($request->has('search')) {
            $search = $request->query('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%$search%")
                    ->orWhere('email', 'like', "%$search%")
                    ->orWhere('phone', 'like', "%$search%");
            });
        }

        $users = $query->latest()->get()->map(fn($u) => [
            'id' => $u->id,
            'name' => $u->name,
            'email' => $u->email,
            'phone' => $u->phone,
            'role' => $u->role,
            'status' => $u->status,
            'created_at' => $u->created_at?->toDateTimeString(),
        ]);

        return $this->success($users, 'Users retrieved');
    }

    public function updateUserStatus(Request $request, $userId)
    {
        $validated = $request->validate([
            'status' => 'required|in:ACTIVE,INACTIVE,SUSPENDED',
        ]);

        $user = User::find($userId);
        if (!$user) {
            return $this->notFound('User not found');
        }

        if ($user->role === 'ADMIN') {
            return $this->error('Cannot modify admin account status', 403);
        }

        $user->update(['status' => $validated['status']]);

        return $this->success([
            'id' => $user->id,
            'name' => $user->name,
            'status' => $user->status,
        ], 'User status updated');
    }

    // ===== ORDER MONITORING =====

    public function getAllOrders(Request $request)
    {
        $query = Order::with(['customer', 'provider', 'payments']);

        if ($request->has('status')) {
            $query->where('status', strtoupper($request->query('status')));
        }

        if ($request->has('customer_id')) {
            $query->where('customer_id', $request->query('customer_id'));
        }

        if ($request->has('provider_id')) {
            $query->where('provider_id', $request->query('provider_id'));
        }

        $orders = $query->latest()->get()->map(fn($o) => [
            'id' => $o->id,
            'order_code' => $o->order_code,
            'customer_name' => $o->customer?->name,
            'provider_name' => $o->provider?->name,
            'status' => $o->status,
            'estimated_price' => $o->estimated_price,
            'final_price' => $o->final_price,
            'schedule_at' => $o->schedule_at,
            'address' => $o->address,
            'dp_status' => $o->payments->where('payment_type', 'DP')->first()?->status,
            'final_status' => $o->payments->where('payment_type', 'FINAL')->first()?->status,
            'created_at' => $o->created_at?->toDateTimeString(),
        ]);

        return $this->success($orders, 'Orders retrieved');
    }

    public function getOrderDetail($orderId)
    {
        $order = Order::with(['customer', 'provider', 'payments', 'review'])->find($orderId);
        if (!$order) {
            return $this->notFound('Order not found');
        }

        return $this->success($order, 'Order detail retrieved');
    }

    // ===== PAYMENT MONITORING =====

    public function getAllPayments(Request $request)
    {
        $query = Payment::with(['order.customer', 'order.provider']);

        if ($request->has('status')) {
            $query->where('status', strtoupper($request->query('status')));
        }

        if ($request->has('payment_type')) {
            $query->where('payment_type', strtoupper($request->query('payment_type')));
        }

        if ($request->has('start_date')) {
            $query->whereDate('created_at', '>=', $request->query('start_date'));
        }

        if ($request->has('end_date')) {
            $query->whereDate('created_at', '<=', $request->query('end_date'));
        }

        $payments = $query->latest()->get()->map(fn($p) => [
            'id' => $p->id,
            'order_id' => $p->order_id,
            'order_code' => $p->order?->order_code,
            'payment_type' => $p->payment_type,
            'amount' => $p->amount,
            'status' => $p->status,
            'customer_name' => $p->order?->customer?->name,
            'provider_name' => $p->order?->provider?->name,
            'paid_at' => $p->paid_at?->toDateTimeString(),
            'created_at' => $p->created_at?->toDateTimeString(),
        ]);

        $summary = [
            'total_amount' => Payment::where('status', 'PAID')->sum('amount'),
            'total_dp' => Payment::where('status', 'PAID')->where('payment_type', 'DP')->sum('amount'),
            'total_final' => Payment::where('status', 'PAID')->where('payment_type', 'FINAL')->sum('amount'),
            'total_transactions' => Payment::where('status', 'PAID')->count(),
        ];

        return $this->success([
            'payments' => $payments,
            'summary' => $summary,
        ], 'Payments retrieved');
    }
}
