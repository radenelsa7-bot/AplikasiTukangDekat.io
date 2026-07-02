<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\MetricsController;
use App\Http\Controllers\Api\N8nIntegrationController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ChatbotController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\TreasurerController;

// Public routes (authentication)
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('/session-login', [AuthController::class, 'sessionLogin'])->middleware('throttle:10,1');
    Route::post('/session-logout', [AuthController::class, 'sessionLogout'])->middleware('throttle:10,1');
});

// Catalog routes (public)
Route::prefix('catalog')->group(function () {
    Route::get('/categories', [CatalogController::class, 'getCategories'])->middleware('throttle:60,1');
    Route::get('/categories/{categoryId}/providers', [CatalogController::class, 'getProvidersByCategory'])->middleware('throttle:30,1');
    Route::get('/providers', [CatalogController::class, 'getProviders'])->middleware('throttle:60,1');
    Route::get('/providers/search', [CatalogController::class, 'searchProviders'])->middleware('throttle:30,1');
    Route::get('/providers/{providerId}', [CatalogController::class, 'getProviderDetail'])->middleware('throttle:30,1');
    Route::get('/providers/{providerId}/reviews', [ReviewController::class, 'getProviderReviews'])->middleware('throttle:30,1');
});

// Protected routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout'])->middleware('throttle:10,1');
    Route::post('/profile/update', [ProfileController::class, 'updateProfile'])->middleware('throttle:10,1');
    Route::delete('/profile/photo', [ProfileController::class, 'deleteProfilePhoto'])->middleware('throttle:10,1');

    Route::prefix('orders')->group(function () {
        Route::post('/', [OrderController::class, 'createOrder'])->middleware(['throttle:10,1', 'role:customer']);
        Route::get('/my-orders', [OrderController::class, 'getMyOrders'])->middleware('throttle:20,1');
        Route::get('/{orderId}', [OrderController::class, 'getOrder'])->middleware('throttle:30,1');
        Route::post('/{orderId}/respond', [OrderController::class, 'respondToOrder'])->middleware(['throttle:10,1', 'role:provider']);
        Route::post('/{orderId}/start-work', [OrderController::class, 'startWork'])->middleware(['throttle:10,1', 'role:provider']);
        Route::post('/{orderId}/complete', [OrderController::class, 'completeOrder'])->middleware(['throttle:10,1', 'role:provider']);
        Route::post('/{orderId}/review', [ReviewController::class, 'createReview'])->middleware(['throttle:10,1', 'role:customer']);
    });

    Route::prefix('payments')->group(function () {
        Route::get('/order/{orderId}', [PaymentController::class, 'getPayments'])->middleware('throttle:30,1');
        Route::get('/{paymentId}', [PaymentController::class, 'getPaymentStatus'])->middleware('throttle:20,1');
        Route::post('/{paymentId}/generate-qris', [PaymentController::class, 'generateQRIS'])->middleware(['throttle:3,1', 'role:customer']);
        Route::post('/{paymentId}/capture-qris', [PaymentController::class, 'captureQris'])->middleware(['throttle:3,1', 'role:customer']);
        Route::post('/{paymentId}/simulate-paid', [PaymentController::class, 'simulatePayment'])->middleware(['throttle:10,1', 'role:customer']);
    });

    Route::get('/reviews/{orderId}', [ReviewController::class, 'getOrderReview'])->middleware('throttle:30,1');

    Route::post('/chatbot/send', [ChatbotController::class, 'sendMessage'])->middleware('throttle:10,1');

    Route::prefix('admin')->middleware('role:admin')->group(function () {
        Route::get('/providers/pending', [AdminController::class, 'getPendingProviders'])->middleware('throttle:30,1');
        Route::patch('/providers/{providerId}/verification', [AdminController::class, 'updateVerification'])->middleware('throttle:20,1');
        Route::post('/providers/{providerId}/verify', [AdminController::class, 'updateVerification'])->middleware('throttle:20,1');
        Route::post('/providers/{providerId}/disable', [AdminController::class, 'disableProvider'])->middleware('throttle:10,1');
        Route::post('/providers/{providerId}/enable', [AdminController::class, 'enableProvider'])->middleware('throttle:10,1');
    });

    Route::prefix('treasurer')->middleware('role:treasurer')->group(function () {
        Route::get('/payments/report', [TreasurerController::class, 'paymentReport'])->middleware('throttle:20,1');
        Route::get('/transactions', [TreasurerController::class, 'paymentReport'])->middleware('throttle:20,1');
        Route::get('/reports/summary', [TreasurerController::class, 'summaryReport'])->middleware('throttle:20,1');
    });

    Route::prefix('provider')->middleware('role:provider')->group(function () {
        Route::put('/profile', [ProfileController::class, 'updateProviderProfile'])->middleware('throttle:10,1');
    });
});

Route::post('/webhooks/payment', [PaymentController::class, 'webhookPaymentCallback'])->middleware('throttle:30,1');

Route::get('/health', function () {
    $dbStatus = 'disconnected';
    try {
        \Illuminate\Support\Facades\DB::connection()->getPdo();
        $dbStatus = 'connected';
    } catch (\Exception $e) {
        $dbStatus = 'error: ' . $e->getMessage();
    }
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toIso8601String(),
        'database' => $dbStatus,
        'version' => config('app.version', '1.0.0'),
    ]);
});
Route::post('/integrations/n8n/events', [N8nIntegrationController::class, 'dispatchEvent'])->middleware('throttle:30,1');
Route::get(config('monitoring.metrics_path', '/metrics'), [MetricsController::class, 'show']);
Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
Route::get('/user-session', function (Request $request) {
    return $request->user() ?: response()->json(['error' => 'Not authenticated'], 401);
})->middleware('auth:sanctum');
