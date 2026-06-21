<?php

namespace App\Http\Controllers\Api;

use App\Services\ChatbotLoggingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatbotMetricsController
{
    /**
     * Get chatbot metrics
     * GET /api/metrics/chatbot
     * 
     * Query parameters:
     * - window: Jendela waktu dalam menit (default: 60)
     * - include_alerts: Include alert data (default: true)
     */
    public function metrics(Request $request): JsonResponse
    {
        // Validasi window parameter
        $window = $request->query('window', 60);
        $window = max(1, min(1440, (int)$window)); // Min 1 menit, max 24 jam

        $metrics = ChatbotLoggingService::getMetrics($window);
        $alerts = [];

        if ($request->query('include_alerts', 'true') === 'true') {
            $alerts = ChatbotLoggingService::checkAlerts($window);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'metrics' => $metrics,
                'alerts' => $alerts,
                'alert_count' => count($alerts),
            ],
        ]);
    }

    /**
     * Get alerts untuk chatbot
     * GET /api/metrics/chatbot/alerts
     */
    public function alerts(Request $request): JsonResponse
    {
        $window = $request->query('window', 60);
        $window = max(1, min(1440, (int)$window));

        $alerts = ChatbotLoggingService::checkAlerts($window);

        return response()->json([
            'success' => true,
            'window_minutes' => $window,
            'alert_count' => count($alerts),
            'alerts' => $alerts,
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    /**
     * Get health status berdasarkan metrics
     * GET /api/metrics/chatbot/health
     */
    public function health(Request $request): JsonResponse
    {
        $window = $request->query('window', 60);
        $metrics = ChatbotLoggingService::getMetrics($window);
        $alerts = ChatbotLoggingService::checkAlerts($window);

        // Determine health status
        $criticalAlerts = array_filter($alerts, fn($a) => $a['severity'] === 'critical');
        $warningAlerts = array_filter($alerts, fn($a) => $a['severity'] === 'warning');

        if (count($criticalAlerts) > 0) {
            $status = 'critical';
            $statusCode = 503;
        } elseif (count($warningAlerts) > 0) {
            $status = 'warning';
            $statusCode = 200;
        } else {
            $status = 'healthy';
            $statusCode = 200;
        }

        return response()->json([
            'status' => $status,
            'healthy' => $status === 'healthy',
            'success_rate' => $metrics['success_rate'],
            'error_rate' => $metrics['error_rate'],
            'total_requests' => $metrics['total_requests'],
            'error_count' => $metrics['error_count'],
            'critical_alerts' => count($criticalAlerts),
            'warning_alerts' => count($warningAlerts),
            'timestamp' => now()->toIso8601String(),
        ], $statusCode);
    }
}
