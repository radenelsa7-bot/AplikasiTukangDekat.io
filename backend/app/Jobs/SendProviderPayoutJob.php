<?php

namespace App\Jobs;

use App\Models\ProviderPayout;
use App\Services\Payout\ProviderPayoutService;
use App\Services\Payout\PayoutGatewayInterface;
use App\Services\Payout\MockPayoutGateway;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendProviderPayoutJob implements ShouldQueue
{
  use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

  // Let the worker retry a few times with backoff
  public int $tries;

  public function __construct(int $payoutId, array $options = [])
  {
    $this->payoutId = $payoutId;
    $this->options = $options;
    $this->tries = (int) config('payout.max_attempts', 3) + 1; // allow one extra for finalization
  }

  /**
   * Dynamic backoff based on attempt count (exponential, capped)
   */
  public function backoff()
  {
    try {
      $p = ProviderPayout::find($this->payoutId);
      $attempts = $p ? $p->attempts()->count() : 0;
    } catch (\Throwable $e) {
      $attempts = 0;
    }

    $seconds = (int) (pow(2, max(0, $attempts - 1)) * 60); // 1m,2m,4m,8m...
    return min($seconds, 3600); // cap to 1 hour
  }
  public int $payoutId;
  public array $options;

  public function handle()
  {
    try {
      $p = ProviderPayout::find($this->payoutId);
      if (!$p) return;
      if ($p->status !== 'PENDING') return;

      // Resolve gateway from container if bound, otherwise fallback to Mock
      if (app()->bound(PayoutGatewayInterface::class)) {
        $gateway = app(PayoutGatewayInterface::class);
      } else {
        $gateway = new MockPayoutGateway();
      }

      $service = new ProviderPayoutService($gateway);
      $service->process($p, $this->options);
    } catch (\Throwable $e) {
      // If job failed due to unexpected exception, mark attempt record (if any)
      Log::error('SendProviderPayoutJob error: ' . $e->getMessage(), ['payoutId' => $this->payoutId]);
      // rethrow to let queue worker handle retries according to $tries
      throw $e;
    }
  }
}
