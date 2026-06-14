<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\N8nIntegrationController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\TreasurerController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\MetricsController;

// Public routes (authentication)
Route::prefix('auth')->group(function () {
    // Throttle register/login to mitigate brute force
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    // Session-based auth (SPA) - no CSRF needed in API routes
    Route::post('/session-login', [AuthController::class, 'sessionLogin']);
    Route::post('/session-logout', [AuthController::class, 'sessionLogout']);
});

// Catalog routes (public)
Route::prefix('catalog')->group(function () {
    Route::get('/categories', [CatalogController::class, 'getCategories']);
    Route::get('/providers', [CatalogController::class, 'getProviders']);
    Route::get('/categories/{categoryId}/providers', [CatalogController::class, 'getProvidersByCategory']);
    Route::get('/providers/search', [CatalogController::class, 'searchProviders']);
    Route::get('/providers/{providerId}', [CatalogController::class, 'getProviderDetail']);
});

// Protected routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Order
    Route::prefix('orders')->group(function () {
        Route::post('/', [OrderController::class, 'createOrder'])->middleware('throttle:10,1');
        Route::get('/my-orders', [OrderController::class, 'getMyOrders']);
        Route::get('/{orderId}', [OrderController::class, 'getOrder']);
        Route::post('/{orderId}/respond', [OrderController::class, 'respondToOrder'])->middleware('throttle:10,1');
        Route::post('/{orderId}/start-work', [OrderController::class, 'startWork'])->middleware('throttle:10,1');
        Route::post('/{orderId}/complete', [OrderController::class, 'completeOrder'])->middleware('throttle:10,1');
        // Review: create review for an order
        Route::post('/{orderId}/review', [ReviewController::class, 'createReview'])->middleware('throttle:10,1');
    });

    // Payment
    Route::prefix('payments')->group(function () {
        Route::get('/order/{orderId}', [PaymentController::class, 'getPayments']);
        Route::get('/{paymentId}', [PaymentController::class, 'getPaymentStatus']);
        Route::post('/{paymentId}/generate-qris', [PaymentController::class, 'generateQRIS']);
        Route::post('/{paymentId}/capture-qris', [PaymentController::class, 'captureQris'])->middleware('throttle:3,1');
    });

    // Review
    Route::prefix('reviews')->group(function () {
        Route::post('/order/{orderId}', [ReviewController::class, 'createReview']);
        Route::get('/provider/{providerId}', [ReviewController::class, 'getProviderReviews']);
        Route::get('/order/{orderId}', [ReviewController::class, 'getOrderReview']);
    });

    // Admin (require ADMIN role)
    Route::prefix('admin')->middleware(\App\Http\Middleware\EnsureRole::class . ':ADMIN')->group(function () {
        Route::get('/providers/pending', [AdminController::class, 'getPendingProviders']);
        Route::patch('/providers/{providerId}/verification', [AdminController::class, 'updateVerification']);
    });

    // Treasurer (require TREASURER role)
    Route::prefix('treasurer')->middleware(\App\Http\Middleware\EnsureRole::class . ':TREASURER')->group(function () {
        Route::get('/payments/report', [TreasurerController::class, 'paymentReport']);
    });
});

// Webhook routes (tanpa authentication)
Route::post('/webhooks/payment', [PaymentController::class, 'webhookPaymentCallback'])->middleware('throttle:30,1');
Route::post('/integrations/n8n/events', [N8nIntegrationController::class, 'dispatchEvent'])->middleware('throttle:30,1');

// Monitoring metrics endpoint
Route::get(config('monitoring.metrics_path', '/metrics'), [MetricsController::class, 'show']);

// Fallback untuk testing
Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Session user endpoint (for SPA)
Route::get('/user-session', function (Request $request) {
    return $request->user() ?: response()->json(['error' => 'Not authenticated'], 401);
})->middleware('auth:sanctum');
