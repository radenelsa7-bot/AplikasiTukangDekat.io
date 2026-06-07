<?php

return [
    'prometheus_enabled' => env('PROMETHEUS_ENABLED', true),
    'payout_failure_window_minutes' => env('MONITORING_PAYOUT_FAILURE_WINDOW', 60),
    'payout_failure_alert_threshold' => env('MONITORING_PAYOUT_FAILURE_ALERT_THRESHOLD', 3),
    'payout_failure_critical_threshold' => env('MONITORING_PAYOUT_FAILURE_CRITICAL_THRESHOLD', 10),
    'metrics_path' => env('MONITORING_METRICS_PATH', '/metrics'),
];
