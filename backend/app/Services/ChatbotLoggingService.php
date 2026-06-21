<?php

namespace App\Services;

use App\Models\ChatbotLog;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;

class ChatbotLoggingService
{
    /**
     * Create log untuk chatbot request
     */
    public static function logRequest(
        int $userId,
        string $userMessage,
        string $status = 'success',
        ?string $assistantMessage = null,
        array $orderContext = [],
        int $responseTimeMs = 0,
        ?string $errorCode = null,
        ?string $errorMessage = null,
        int $retryCount = 0,
        ?int $tokensUsed = null,
        ?float $apiCostUsd = null,
        array $metadata = []
    ): ?ChatbotLog {
        try {
            if (!config('monitoring.chatbot.logging.enabled')) {
                return null;
            }

            // Skip logging berdasarkan sampling rate
            if (!self::shouldLogBasedOnSampling($status)) {
                return null;
            }

            $requestId = Str::uuid()->toString();

            $logData = [
                'user_id' => $userId,
                'request_id' => $requestId,
                'user_message' => substr($userMessage, 0, 5000),
                'assistant_message' => $assistantMessage ? substr($assistantMessage, 0, 5000) : null,
                'order_context' => $orderContext,
                'response_time_ms' => $responseTimeMs,
                'status' => $status,
                'error_code' => $errorCode,
                'error_message' => $errorMessage ? substr($errorMessage, 0, 1000) : null,
                'retry_count' => $retryCount,
                'tokens_used' => $tokensUsed,
                'api_cost_usd' => $apiCostUsd,
                'metadata' => array_merge($metadata, [
                    'ip_address' => request()->ip(),
                    'user_agent' => request()->userAgent(),
                ]),
            ];

            // Log ke database jika enabled
            if (config('monitoring.chatbot.logging.database')) {
                $chatbotLog = ChatbotLog::create($logData);

                // Log ke Laravel logger
                $logLevel = config('monitoring.chatbot.logging.log_level', 'info');
                Log::channel(config('monitoring.chatbot.logging.channel'))->log(
                    $logLevel,
                    "Chatbot request logged",
                    [
                        'request_id' => $requestId,
                        'user_id' => $userId,
                        'status' => $status,
                        'response_time_ms' => $responseTimeMs,
                        'error_code' => $errorCode,
                    ]
                );

                return $chatbotLog;
            }

            return null;
        } catch (\Exception $e) {
            Log::error('Failed to log chatbot request', [
                'error' => $e->getMessage(),
                'user_id' => $userId,
            ]);

            return null;
        }
    }

    /**
     * Check apakah request harus di-log berdasarkan sampling rate
     */
    private static function shouldLogBasedOnSampling(string $status): bool
    {
        $samplingConfig = config('monitoring.chatbot.sampling');

        if (!$samplingConfig['enabled']) {
            return true;
        }

        // Always log errors
        if ($samplingConfig['always_log_errors'] && $status === 'error') {
            return true;
        }

        // Check sampling rate
        return rand(1, 100) / 100 <= $samplingConfig['rate'];
    }

    /**
     * Get metrics untuk chatbot
     */
    public static function getMetrics(int $minutesWindow = 60): array
    {
        $sinceTime = now()->subMinutes($minutesWindow);

        $totalRequests = ChatbotLog::fromDate($sinceTime)->count();
        $successCount = ChatbotLog::fromDate($sinceTime)->byStatus('success')->count();
        $errorCount = ChatbotLog::fromDate($sinceTime)->byStatus('error')->count();
        $rateLimitedCount = ChatbotLog::fromDate($sinceTime)->byStatus('rate_limited')->count();
        $retryCount = ChatbotLog::fromDate($sinceTime)->byStatus('retry')->count();

        // Calculate rates
        $successRate = $totalRequests > 0 ? ($successCount / $totalRequests) : 0;
        $errorRate = $totalRequests > 0 ? ($errorCount / $totalRequests) : 0;
        $rateLimitRate = $totalRequests > 0 ? ($rateLimitedCount / $totalRequests) : 0;

        // Response time stats
        $responseTimeStats = ChatbotLog::fromDate($sinceTime)
            ->where('response_time_ms', '>', 0)
            ->selectRaw('AVG(response_time_ms) as avg_response_time, MIN(response_time_ms) as min_response_time, MAX(response_time_ms) as max_response_time')
            ->first();

        // Token usage
        $tokenStats = ChatbotLog::fromDate($sinceTime)
            ->where('tokens_used', '>', 0)
            ->selectRaw('SUM(tokens_used) as total_tokens, AVG(tokens_used) as avg_tokens')
            ->first();

        // Cost stats
        $costStats = ChatbotLog::fromDate($sinceTime)
            ->where('api_cost_usd', '>', 0)
            ->selectRaw('SUM(api_cost_usd) as total_cost, AVG(api_cost_usd) as avg_cost')
            ->first();

        // Error distribution
        $errorDistribution = ChatbotLog::fromDate($sinceTime)
            ->where('status', 'error')
            ->selectRaw('error_code, COUNT(*) as count')
            ->groupBy('error_code')
            ->pluck('count', 'error_code')
            ->toArray();

        return [
            'window_minutes' => $minutesWindow,
            'timestamp' => now()->toIso8601String(),
            'total_requests' => $totalRequests,
            'success_count' => $successCount,
            'error_count' => $errorCount,
            'rate_limited_count' => $rateLimitedCount,
            'retry_count' => $retryCount,
            'success_rate' => round($successRate, 4),
            'error_rate' => round($errorRate, 4),
            'rate_limit_rate' => round($rateLimitRate, 4),
            'response_time' => [
                'avg_ms' => round($responseTimeStats->avg_response_time ?? 0, 2),
                'min_ms' => $responseTimeStats->min_response_time ?? 0,
                'max_ms' => $responseTimeStats->max_response_time ?? 0,
            ],
            'tokens' => [
                'total' => $tokenStats->total_tokens ?? 0,
                'average' => round($tokenStats->avg_tokens ?? 0, 2),
            ],
            'cost' => [
                'total_usd' => round($costStats->total_cost ?? 0, 6),
                'average_usd' => round($costStats->avg_cost ?? 0, 8),
                'currency' => 'USD',
            ],
            'error_distribution' => $errorDistribution,
        ];
    }

    /**
     * Check apakah ada alert yang perlu dipicu
     */
    public static function checkAlerts(int $minutesWindow = 60): array
    {
        $metrics = self::getMetrics($minutesWindow);
        $alerts = [];
        $alertConfig = config('monitoring.chatbot.alerts');

        // Check error rate
        if ($metrics['error_rate'] > $alertConfig['error_rate_threshold']) {
            $alerts[] = [
                'type' => 'HIGH_ERROR_RATE',
                'severity' => 'warning',
                'message' => "Error rate adalah {$metrics['error_rate']} (threshold: {$alertConfig['error_rate_threshold']})",
                'value' => $metrics['error_rate'],
                'threshold' => $alertConfig['error_rate_threshold'],
            ];
        }

        // Check response time
        if ($metrics['response_time']['avg_ms'] > $alertConfig['response_time_threshold_ms']) {
            $alerts[] = [
                'type' => 'HIGH_RESPONSE_TIME',
                'severity' => 'warning',
                'message' => "Response time rata-rata {$metrics['response_time']['avg_ms']}ms (threshold: {$alertConfig['response_time_threshold_ms']}ms)",
                'value' => $metrics['response_time']['avg_ms'],
                'threshold' => $alertConfig['response_time_threshold_ms'],
            ];
        }

        // Check rate limit
        if ($metrics['rate_limit_rate'] > $alertConfig['rate_limit_threshold']) {
            $alerts[] = [
                'type' => 'HIGH_RATE_LIMIT',
                'severity' => 'info',
                'message' => "Rate limit rate adalah {$metrics['rate_limit_rate']} (threshold: {$alertConfig['rate_limit_threshold']})",
                'value' => $metrics['rate_limit_rate'],
                'threshold' => $alertConfig['rate_limit_threshold'],
            ];
        }

        // Check critical errors
        foreach ($alertConfig['critical_errors'] as $errorCode => $shouldAlert) {
            if ($shouldAlert && isset($metrics['error_distribution'][$errorCode])) {
                $count = $metrics['error_distribution'][$errorCode];
                if ($count > 0) {
                    $alerts[] = [
                        'type' => 'CRITICAL_ERROR_DETECTED',
                        'severity' => 'critical',
                        'message' => "Error {$errorCode} terjadi {$count} kali dalam {$minutesWindow} menit terakhir",
                        'error_code' => $errorCode,
                        'count' => $count,
                    ];
                }
            }
        }

        return $alerts;
    }

    /**
     * Cleanup logs lama
     */
    public static function cleanupOldLogs(): int
    {
        $config = config('monitoring.chatbot.retention');
        
        if (!$config['auto_cleanup']) {
            return 0;
        }

        $cutoffDate = now()->subDays($config['days']);
        
        return ChatbotLog::where('created_at', '<', $cutoffDate)->delete();
    }
}
