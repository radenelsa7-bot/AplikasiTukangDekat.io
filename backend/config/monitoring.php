<?php

return [
    'prometheus_enabled' => env('PROMETHEUS_ENABLED', true),
    'payout_failure_window_minutes' => env('MONITORING_PAYOUT_FAILURE_WINDOW', 60),
    'payout_failure_alert_threshold' => env('MONITORING_PAYOUT_FAILURE_ALERT_THRESHOLD', 3),
    'payout_failure_critical_threshold' => env('MONITORING_PAYOUT_FAILURE_CRITICAL_THRESHOLD', 10),
    'metrics_path' => env('MONITORING_METRICS_PATH', '/metrics'),

    /**
     * Chatbot Monitoring & Alert Configuration
     * Konfigurasi untuk monitoring Gemini API calls dan alerts
     */
    'chatbot' => [
        // Logging Configuration
        'logging' => [
            'enabled' => env('CHATBOT_LOGGING_ENABLED', true),
            'channel' => env('CHATBOT_LOG_CHANNEL', 'stack'),
            'database' => env('CHATBOT_LOG_TO_DATABASE', true),
            'log_level' => env('CHATBOT_LOG_LEVEL', 'info'),
        ],

        // Alert Thresholds
        'alerts' => [
            'error_rate_threshold' => env('CHATBOT_ALERT_ERROR_RATE', 0.05), // 5%
            'error_rate_window_minutes' => env('CHATBOT_ALERT_ERROR_WINDOW', 60),
            'response_time_threshold_ms' => env('CHATBOT_ALERT_RESPONSE_TIME_MS', 5000),
            'response_time_window_minutes' => env('CHATBOT_ALERT_RESPONSE_TIME_WINDOW', 60),
            'rate_limit_threshold' => env('CHATBOT_ALERT_RATE_LIMIT', 0.10), // 10%
            'rate_limit_window_minutes' => env('CHATBOT_ALERT_RATE_LIMIT_WINDOW', 60),
            'critical_errors' => [
                'GEMINI_API_ERROR' => true,
                'GEMINI_NOT_CONFIGURED' => true,
                'GEMINI_RESPONSE_INVALID' => true,
                'TIMEOUT' => true,
            ],
        ],

        // Retention Policy
        'retention' => [
            'days' => env('CHATBOT_LOG_RETENTION_DAYS', 90),
            'auto_cleanup' => env('CHATBOT_LOG_AUTO_CLEANUP', true),
            'cleanup_interval_days' => env('CHATBOT_LOG_CLEANUP_INTERVAL', 7),
        ],

        // Performance Metrics
        'metrics' => [
            'enabled' => env('CHATBOT_METRICS_ENABLED', true),
            'histogram_buckets' => [100, 500, 1000, 2000, 5000, 10000],
            'track_tokens' => env('CHATBOT_TRACK_TOKENS', true),
            'track_cost' => env('CHATBOT_TRACK_COST', true),
        ],

        // Cost Estimation
        'cost_model' => [
            'input_token_cost' => 0.0000005,
            'output_token_cost' => 0.0000015,
            'currency' => 'USD',
        ],

        // Notifications
        'notifications' => [
            'enabled' => env('CHATBOT_ALERTS_ENABLED', true),
            'channels' => [
                'email' => env('CHATBOT_ALERT_EMAIL_ENABLED', true),
                'slack' => env('CHATBOT_ALERT_SLACK_ENABLED', false),
                'database' => env('CHATBOT_ALERT_DATABASE_ENABLED', true),
            ],
            'recipients' => explode(',', env('CHATBOT_ALERT_RECIPIENTS', 'admin@tukangdekat.local')),
        ],

        // Sampling for high traffic
        'sampling' => [
            'enabled' => env('CHATBOT_LOG_SAMPLING_ENABLED', false),
            'rate' => env('CHATBOT_LOG_SAMPLING_RATE', 1.0),
            'always_log_errors' => true,
        ],
    ],
];
