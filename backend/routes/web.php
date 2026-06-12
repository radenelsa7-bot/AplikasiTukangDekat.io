<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

Route::get('/', function () {
    return view('welcome');
});

// Auth routes (kept for compatibility with views that reference route('login'))
Route::get('/login', function () {
    return view('auth.login');
})->name('login');
Route::get('/register', function () {
    return view('auth.register');
})->name('register');

// Simple dashboard placeholder (UI-only). Actual backend auth integration
// can be connected later (Sanctum/session/token).
Route::get('/dashboard', function () {
    return view('app.dashboard');
})->name('dashboard');

Route::middleware(['auth'])->group(function () {
    Route::get('/admin/dashboard', function () {
        return view('admin.dashboard');
    })->name('admin.dashboard');

    Route::get('/admin/categories', function () {
        return view('admin.categories');
    })->name('admin.categories');

    Route::get('/admin/providers', function () {
        return view('admin.providers');
    })->name('admin.providers');

    Route::get('/admin/orders', function () {
        return view('admin.orders');
    })->name('admin.orders');

    Route::get('/admin/treasurer/report', [App\Http\Controllers\Admin\TreasurerWebController::class, 'index'])->name('admin.treasurer.report');
    Route::get('/admin/treasurer/provider-payouts', [App\Http\Controllers\Admin\ProviderPayoutController::class, 'index'])->name('admin.treasurer.provider_payouts');
    Route::get('/admin/treasurer/provider-payouts/{id}', [App\Http\Controllers\Admin\ProviderPayoutController::class, 'detail'])->name('admin.treasurer.provider_payout_detail');
});

// Admin/Treasurer UI
Route::middleware(['auth'])->group(function () {
    Route::get('/admin/treasurer/payments', [App\Http\Controllers\Admin\TreasurerWebController::class, 'index'])->name('admin.treasurer.report');

    // Provider payouts UI + actions
    Route::get('/admin/treasurer/provider-payouts', [App\Http\Controllers\Admin\ProviderPayoutController::class, 'index'])->name('admin.treasurer.provider_payouts');
    Route::post('/admin/treasurer/provider-payouts/{id}/send', [App\Http\Controllers\Admin\ProviderPayoutController::class, 'send'])->name('admin.treasurer.provider_payouts.send');
    Route::post('/admin/treasurer/provider-payouts/send-batch', [App\Http\Controllers\Admin\ProviderPayoutController::class, 'sendBatch'])->name('admin.treasurer.provider_payouts.send_batch');
    Route::get('/admin/treasurer/provider-payouts/{id}', [App\Http\Controllers\Admin\ProviderPayoutController::class, 'detail'])->name('admin.treasurer.provider_payouts.detail');
    Route::post('/admin/treasurer/provider-payouts/{id}/retry', [App\Http\Controllers\Admin\ProviderPayoutController::class, 'retry'])->name('admin.treasurer.provider_payouts.retry');

    // Route to trigger provider payouts (admin/treasurer only)
    Route::post('/admin/treasurer/process-payouts', function (Illuminate\Http\Request $request) {
        $user = Auth::user();
        if (!$user || !in_array($user->role, ['TREASURER', 'ADMIN'])) {
            abort(403);
        }

        // Inline payout aggregation (same logic as artisan command)
        $payments = \App\Models\Payment::where('status', 'PAID')
            ->where('provider_payout', '>', 0)
            ->where(function ($q) {
                $q->whereNull('provider_payout_processed')->orWhere('provider_payout_processed', false);
            })->get();

        if ($payments->isEmpty()) {
            return redirect()->back()->with('status', 'No payouts to process');
        }

        $grouped = $payments->groupBy('order.provider_id');

        DB::beginTransaction();
        try {
            foreach ($grouped as $providerId => $group) {
                $sum = $group->sum('provider_payout');
                $paymentIds = $group->pluck('id')->values()->all();

                \App\Models\ProviderPayout::create([
                    'provider_id' => $providerId,
                    'amount' => $sum,
                    'payment_ids' => $paymentIds,
                    'status' => 'PENDING',
                ]);

                \App\Models\Payment::whereIn('id', $paymentIds)->update([
                    'provider_payout_processed' => true,
                    'provider_paid_at' => now(),
                ]);
            }

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            return redirect()->back()->with('error', 'Payout processing failed: ' . $e->getMessage());
        }

        return redirect()->back()->with('status', 'Payouts processed');
    })->name('admin.treasurer.process_payouts');
});
