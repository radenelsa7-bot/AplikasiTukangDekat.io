<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use App\Services\MonitoringService;
use App\Services\NotificationLogService;

class AlertFailedPayoutsCommandTest extends TestCase
{
    public function test_does_not_alert_when_failed_attempts_are_below_threshold()
    {
        config(['monitoring.payout_failure_alert_threshold' => 3]);
        config(['services.payouts.alert_webhook' => null, 'services.payouts.alert_email' => null]);

        $service = new class extends MonitoringService {
            public function failedPayoutsCount(int $windowMinutes = null): int
            {
                return 2;
            }
        };

        $logger = new class extends NotificationLogService {
            public function log(string $eventName, string $channel, array $payload, string $status): void
            {
                // no-op in tests
            }
        };

        $this->instance(MonitoringService::class, $service);
        $this->instance(NotificationLogService::class, $logger);

        Notification::fake();
        Http::fake();

        $this->artisan('payouts:alert', ['--since' => 60])
            ->expectsOutput('Found 2 failed attempts in last 60 minutes. Threshold 3 not reached.')
            ->assertExitCode(0);

        Http::assertNothingSent();
        Notification::assertNothingSent();
    }

    public function test_alerts_and_logs_notification_when_threshold_is_reached()
    {
        config(['monitoring.payout_failure_alert_threshold' => 2]);
        config([
            'services.payouts.alert_webhook' => 'https://example.com/alert',
            'services.payouts.alert_email' => 'alerts@example.com',
        ]);

        $service = new class extends MonitoringService {
            public function failedPayoutsCount(int $windowMinutes = null): int
            {
                return 2;
            }
        };

        $logger = new class extends NotificationLogService {
            public function log(string $eventName, string $channel, array $payload, string $status): void
            {
                // no-op in tests
            }
        };

        $this->instance(MonitoringService::class, $service);
        $this->instance(NotificationLogService::class, $logger);

        Notification::fake();
        Http::fake();

        $this->artisan('payouts:alert', ['--since' => 60])
            ->expectsOutput('Found 2 failed attempts in last 60 minutes. Threshold 2 reached (severity: warning).')
            ->expectsOutput('Posted alert to webhook')
            ->expectsOutput('Email sent to alerts@example.com')
            ->assertExitCode(0);

        Http::assertSentCount(1);
        Notification::assertSentTo(
            new \Illuminate\Notifications\AnonymousNotifiable,
            \App\Notifications\FailedPayoutsAlert::class
        );
    }

    public function test_alerts_with_critical_severity_when_failed_attempts_exceed_critical_threshold()
    {
        config(['monitoring.payout_failure_alert_threshold' => 3]);
        config(['monitoring.payout_failure_critical_threshold' => 5]);
        config([
            'services.payouts.alert_webhook' => 'https://example.com/alert',
            'services.payouts.alert_email' => 'alerts@example.com',
        ]);

        $service = new class extends MonitoringService {
            public function failedPayoutsCount(int $windowMinutes = null): int
            {
                return 7;
            }
        };

        $logger = new class extends NotificationLogService {
            public function log(string $eventName, string $channel, array $payload, string $status): void
            {
                // no-op in tests
            }
        };

        $this->instance(MonitoringService::class, $service);
        $this->instance(NotificationLogService::class, $logger);

        Notification::fake();
        Http::fake();

        $this->artisan('payouts:alert', ['--since' => 60])
            ->expectsOutput('Found 7 failed attempts in last 60 minutes. Threshold 3 reached (severity: critical).')
            ->expectsOutput('Posted alert to webhook')
            ->expectsOutput('Email sent to alerts@example.com')
            ->assertExitCode(0);

        Http::assertSentCount(1);
        Notification::assertSentTo(
            new \Illuminate\Notifications\AnonymousNotifiable,
            \App\Notifications\FailedPayoutsAlert::class
        );
    }
}
