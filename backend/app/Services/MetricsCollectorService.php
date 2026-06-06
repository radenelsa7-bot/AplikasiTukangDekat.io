<?php

namespace App\Services;

use App\Models\NotificationLog;
use App\Models\PayoutProviderResponse;
use App\Services\MonitoringService;

class MetricsCollectorService
{
    protected MonitoringService $monitoringService;

    public function __construct(MonitoringService $monitoringService)
    {
        $this->monitoringService = $monitoringService;
    }

    public function collect(int $windowMinutes = null): array
    {
        $windowMinutes = $windowMinutes ?? config('monitoring.payout_failure_window_minutes', 60);

        $recentAttempts = $this->monitoringService->payoutAttemptsCount($windowMinutes);
        $recentFailed = $this->monitoringService->failedPayoutsCount($windowMinutes);
        $severity = $this->monitoringService->alertSeverity($windowMinutes);

        $totalAttempts = $this->monitoringService->payoutAttemptsCount();
        $failedAttempts = $this->monitoringService->failedPayoutsCount();

        return [
            'app_metrics_generated_timestamp' => now()->unix(),
            'monitoring_window_minutes' => $windowMinutes,
            'payout_attempts_total' => $totalAttempts,
            'failed_payout_attempts_total' => $failedAttempts,
            'recent_payout_attempts_total' => $recentAttempts,
            'recent_failed_payout_attempts_total' => $recentFailed,
            'payout_failure_rate_percentage_last_window' => $recentAttempts === 0 ? 0.0 : round((100 * $recentFailed) / max(1, $recentAttempts), 2),
            'payout_provider_response_records_total' => PayoutProviderResponse::count(),
            'notification_logs_total' => NotificationLog::count(),
            'alert_trigger_threshold' => config('monitoring.payout_failure_alert_threshold', 3),
            'alert_critical_threshold' => config('monitoring.payout_failure_critical_threshold', 10),
            'alert_triggered' => $recentFailed >= config('monitoring.payout_failure_alert_threshold', 3) ? 1 : 0,
            'alert_severity' => $severity === 'critical' ? 2 : ($severity === 'warning' ? 1 : 0),
        ];
    }

    public function toPrometheusText(array $metrics): string
    {
        $lines = [];

        foreach ($metrics as $name => $value) {
            if (is_bool($value)) {
                $value = $value ? 1 : 0;
            }

            $lines[] = sprintf('%s %s', $this->normalizeMetricName($name), $value);
        }

        return implode("\n", $lines) . "\n";
    }

    private function normalizeMetricName(string $name): string
    {
        return 'tukangdekat_' . preg_replace('/[^a-z0-9_]/', '_', strtolower($name));
    }
}
