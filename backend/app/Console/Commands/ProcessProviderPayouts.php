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
  protected $signature = 'payouts:process {--dry-run}';
  protected $description = 'Aggregate provider payouts for PAID payments and create payout records';

  public function handle()
  {
    $this->info('Starting provider payouts process...');

    // Find paid payments with provider_payout > 0 and not yet processed
    $query = Payment::join('orders', 'payments.order_id', '=', 'orders.id')
      ->where('payments.status', 'PAID')
      ->where('payments.provider_payout', '>', 0)
      ->select('payments.*', 'orders.provider_id as order_provider_id');

    if (Schema::hasColumn('payments', 'provider_payout_processed')) {
      $query->where(function ($q) {
        $q->whereNull('payments.provider_payout_processed')
          ->orWhere('payments.provider_payout_processed', false);
      });
    }

    try {
      $payments = $query->get();
    } catch (\Illuminate\Database\QueryException $e) {
      if (str_contains($e->getMessage(), 'no such column: payments.provider_payout_processed')) {
        $this->warn('provider_payout_processed column missing; retrying without the processed filter.');
        $payments = Payment::join('orders', 'payments.order_id', '=', 'orders.id')
          ->where('payments.status', 'PAID')
          ->where('payments.provider_payout', '>', 0)
          ->select('payments.*', 'orders.provider_id as order_provider_id')
          ->get();
      } else {
        throw $e;
      }
    }

    $this->info('Found ' . $payments->count() . ' eligible payments for payout processing.');

    if ($payments->isEmpty()) {
      $this->info('No payouts to process.');
      return 0;
    }

    // Group by provider_id from the joined order data
    $grouped = $payments->groupBy('order_provider_id');

    DB::beginTransaction();
    try {
      foreach ($grouped as $providerId => $group) {
        $sum = $group->sum('provider_payout');
        $paymentIds = $group->pluck('id')->values()->all();

        $this->info("Creating payout for provider {$providerId} amount {$sum}");

        if (!$this->option('dry-run')) {
          $payout = ProviderPayout::create([
            'provider_id' => $providerId,
            'amount' => $sum,
            'payment_ids' => $paymentIds,
            'status' => 'PENDING',
          ]);

          // mark payments processed
          $updateData = ['provider_paid_at' => Carbon::now()];
          if (Schema::hasColumn('payments', 'provider_payout_processed')) {
            $updateData['provider_payout_processed'] = true;
          }

          Payment::whereIn('id', $paymentIds)->update($updateData);
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
