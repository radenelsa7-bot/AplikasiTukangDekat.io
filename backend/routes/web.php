<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

Route::get('/', function () {
    return view('welcome');
});

// Auth routes (kept for compatibility with views that reference route('login'))
Route::get('/login', function () {
    return redirect('/');
})->name('login');
Route::get('/register', function () {
    return redirect('/');
})->name('register');

// Admin/Treasurer UI
use App\Http\Controllers\Admin\TreasurerWebController;
use App\Http\Controllers\Api\TreasurerController;
use App\Http\Controllers\Admin\ProviderPayoutController;

Route::middleware(['auth'])->group(function () {
    Route::get('/admin/treasurer/payments', [TreasurerWebController::class, 'index'])->name('admin.treasurer.report');

    // Provider payouts UI + actions
    Route::get('/admin/treasurer/provider-payouts', [ProviderPayoutController::class, 'index'])->name('admin.treasurer.provider_payouts');
    Route::post('/admin/treasurer/provider-payouts/{id}/send', [ProviderPayoutController::class, 'send'])->name('admin.treasurer.provider_payouts.send');
    Route::post('/admin/treasurer/provider-payouts/send-batch', [ProviderPayoutController::class, 'sendBatch'])->name('admin.treasurer.provider_payouts.send_batch');
    Route::get('/admin/treasurer/provider-payouts/{id}', [ProviderPayoutController::class, 'detail'])->name('admin.treasurer.provider_payouts.detail');
    Route::post('/admin/treasurer/provider-payouts/{id}/retry', [ProviderPayoutController::class, 'retry'])->name('admin.treasurer.provider_payouts.retry');

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

Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/api/treasurer/payments/report', [TreasurerController::class, 'paymentReport'])->name('api.treasurer.report');
});
