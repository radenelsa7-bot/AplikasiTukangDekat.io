<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Payment;
use App\Models\ProviderPayout;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Carbon\Carbon;

class ProcessProviderPayouts extends Command
{
  protected $signature = 'payouts:process {--dry-run=0}';
  protected $description = 'Aggregate provider payouts for PAID payments and create payout records';

  public function handle()
  {
    $this->info('Starting provider payouts process...');

    // Find paid payments with provider_payout > 0 and eligible for processing.
    $payments = Payment::with('order')
      ->where('status', 'PAID')
      ->where('provider_payout', '>', 0)
      ->get()
      ->filter(function ($payment) {
        if (!$payment->order || !$payment->order->provider_id) {
          return false;
        }

        if (!Schema::hasColumn('payments', 'provider_payout_processed')) {
          return true;
        }

        return (int) ($payment->provider_payout_processed ?? 0) === 0;
      })
      ->values();

    $this->info('Found ' . $payments->count() . ' eligible payments for payout processing.');

    if ($payments->isEmpty()) {
      $this->info('No payouts to process.');
      return 0;
    }

    // Group by provider_id from related order
    $grouped = $payments->groupBy(function ($payment) {
      return $payment->order->provider_id;
    });
    $isDryRun = filter_var($this->option('dry-run'), FILTER_VALIDATE_BOOLEAN);

    DB::beginTransaction();
    try {
      foreach ($grouped as $providerId => $group) {
        $sum = $group->sum('provider_payout');
        $paymentIds = $group->pluck('id')->values()->all();

        $this->info("Creating payout for provider {$providerId} amount {$sum}");

        if (!$isDryRun) {
          $payout = ProviderPayout::create([
            'provider_id' => $providerId,
            'amount' => $sum,
            'payment_ids' => $paymentIds,
            'status' => 'PENDING',
          ]);

          // mark payments processed
          $updateData = [];
          if (Schema::hasColumn('payments', 'provider_paid_at')) {
            $updateData['provider_paid_at'] = Carbon::now();
          }
          if (Schema::hasColumn('payments', 'provider_payout_processed')) {
            $updateData['provider_payout_processed'] = true;
          }

          if (!empty($updateData)) {
            Payment::whereIn('id', $paymentIds)->update($updateData);
          }
        }
      }

      DB::commit();
      $this->info('Provider payouts aggregated successfully.');
    } catch (\Exception $e) {
      DB::rollBack();
      $this->error('Error processing payouts: ' . $e->getMessage());
      return 1;
    }

    return 0;
  }
}
