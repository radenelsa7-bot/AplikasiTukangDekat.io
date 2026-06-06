<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Notification;
use App\Notifications\FailedPayoutsAlert;
use App\Services\MonitoringService;
use App\Services\NotificationLogService;

class AlertFailedPayouts extends Command
{
  protected $signature = 'payouts:alert {--since=60 : minutes to look back}';
  protected $description = 'Alert if failed payout attempts exceed the configured threshold';

  public function handle(MonitoringService $monitoringService, NotificationLogService $notificationLogService)
  {
    $since = (int) $this->option('since');
    $threshold = config('monitoring.payout_failure_alert_threshold', 3);
    $critical = config('monitoring.payout_failure_critical_threshold', 10);
    $count = $monitoringService->failedPayoutsCount($since);
    $severity = $monitoringService->alertSeverity($since);

    if ($count < $threshold) {
      $this->info("Found {$count} failed attempts in last {$since} minutes. Threshold {$threshold} not reached.");
      return 0;
    }

    $this->info("Found {$count} failed attempts in last {$since} minutes. Threshold {$threshold} reached (severity: {$severity}).");

    $webhook = config('services.payouts.alert_webhook');
    $email = config('services.payouts.alert_email');
    $payload = [
      'failed_count' => $count,
      'window_minutes' => $since,
      'threshold' => $threshold,
      'critical_threshold' => $critical,
      'severity' => $severity,
      'timestamp' => now()->toDateTimeString(),
    ];

    if (! $webhook && ! $email) {
      $this->error('No alert destination configured. Set PAYOUT_ALERT_EMAIL or PAYOUT_ALERT_WEBHOOK.');
      return 1;
    }

    if ($webhook) {
      try {
        Http::timeout(5)->post($webhook, $payload);
        $this->info('Posted alert to webhook');
        $notificationLogService->log('failed_payouts_alert', 'WA', $payload, 'SENT');
      } catch (\Throwable $e) {
        $this->error('Webhook post failed: ' . $e->getMessage());
        $notificationLogService->log('failed_payouts_alert', 'WA', $payload, 'FAILED');
      }
    }

    if ($email) {
      try {
        Notification::route('mail', $email)->notify(new FailedPayoutsAlert(
          $count,
          $since,
          $threshold,
          $critical,
          $severity,
          now()->toDateTimeString(),
        ));
        $this->info('Email sent to ' . $email);
        $notificationLogService->log('failed_payouts_alert', 'EMAIL', $payload, 'SENT');
      } catch (\Throwable $e) {
        $this->error('Email send failed: ' . $e->getMessage());
        $notificationLogService->log('failed_payouts_alert', 'EMAIL', $payload, 'FAILED');
      }
    }

    return 0;
  }
}
