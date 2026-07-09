<?php

namespace App\Services;

use App\Models\ProviderPayoutAttempt;

class MonitoringService
{
    public function failedPayoutsCount(?int $windowMinutes = null): int
    {
        $windowMinutes = $windowMinutes ?? config('monitoring.payout_failure_window_minutes', 60);
        $cutoff = now()->subMinutes($windowMinutes);

        return ProviderPayoutAttempt::where('status', 'FAILED')
            ->where('created_at', '>=', $cutoff)
            ->count();
    }

    public function payoutAttemptsCount(?int $windowMinutes = null): int
    {
        $windowMinutes = $windowMinutes ?? config('monitoring.payout_failure_window_minutes', 60);
        $cutoff = now()->subMinutes($windowMinutes);

        return ProviderPayoutAttempt::where('created_at', '>=', $cutoff)
            ->count();
    }

    public function payoutFailureRate(?int $windowMinutes = null): float
    {
        $windowMinutes = $windowMinutes ?? config('monitoring.payout_failure_window_minutes', 60);
        $cutoff = now()->subMinutes($windowMinutes);

        $total = ProviderPayoutAttempt::where('created_at', '>=', $cutoff)->count();
        $failed = ProviderPayoutAttempt::where('status', 'FAILED')
            ->where('created_at', '>=', $cutoff)
            ->count();

        return $total === 0 ? 0.0 : round((100 * $failed) / $total, 2);
    }

    public function alertThresholdExceeded(?int $windowMinutes = null): bool
    {
        $threshold = config('monitoring.payout_failure_alert_threshold', 3);
        return $this->failedPayoutsCount($windowMinutes) >= $threshold;
    }

    public function alertSeverity(?int $windowMinutes = null): string
    {
        $failed = $this->failedPayoutsCount($windowMinutes);
        $critical = config('monitoring.payout_failure_critical_threshold', 10);
        $threshold = config('monitoring.payout_failure_alert_threshold', 3);

        if ($failed >= $critical) {
            return 'critical';
        }

        if ($failed >= $threshold) {
            return 'warning';
        }

        return 'none';
    }
}
