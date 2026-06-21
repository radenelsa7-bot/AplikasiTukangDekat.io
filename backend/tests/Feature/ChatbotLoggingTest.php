<?php

namespace Tests\Feature;

use App\Models\ChatbotLog;
use App\Models\User;
use App\Services\ChatbotLoggingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChatbotLoggingTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test log creation untuk successful request
     */
    public function test_log_successful_chatbot_request(): void
    {
        $user = User::factory()->create();

        $log = ChatbotLoggingService::logRequest(
            userId: $user->id,
            userMessage: 'Test message',
            status: 'success',
            assistantMessage: 'Test response',
            orderContext: ['order_id' => 1],
            responseTimeMs: 1500,
            tokensUsed: 250
        );

        $this->assertNotNull($log);
        $this->assertDatabaseHas('chatbot_logs', [
            'user_id' => $user->id,
            'status' => 'success',
            'response_time_ms' => 1500,
            'tokens_used' => 250,
        ]);
    }

    /**
     * Test log creation untuk error request
     */
    public function test_log_error_chatbot_request(): void
    {
        $user = User::factory()->create();

        ChatbotLoggingService::logRequest(
            userId: $user->id,
            userMessage: 'Test message',
            status: 'error',
            errorCode: 'GEMINI_API_ERROR',
            errorMessage: 'API connection failed',
            responseTimeMs: 5000,
            retryCount: 2
        );

        $this->assertDatabaseHas('chatbot_logs', [
            'user_id' => $user->id,
            'status' => 'error',
            'error_code' => 'GEMINI_API_ERROR',
            'retry_count' => 2,
        ]);
    }

    /**
     * Test metrics calculation
     */
    public function test_get_metrics(): void
    {
        $user = User::factory()->create();

        // Create successful logs
        ChatbotLoggingService::logRequest(
            userId: $user->id,
            userMessage: 'Message 1',
            status: 'success',
            responseTimeMs: 1000,
            tokensUsed: 200
        );

        ChatbotLoggingService::logRequest(
            userId: $user->id,
            userMessage: 'Message 2',
            status: 'success',
            responseTimeMs: 2000,
            tokensUsed: 300
        );

        // Create error log
        ChatbotLoggingService::logRequest(
            userId: $user->id,
            userMessage: 'Message 3',
            status: 'error',
            errorCode: 'TIMEOUT',
            responseTimeMs: 3000
        );

        $metrics = ChatbotLoggingService::getMetrics(60);

        $this->assertEquals(3, $metrics['total_requests']);
        $this->assertEquals(2, $metrics['success_count']);
        $this->assertEquals(1, $metrics['error_count']);
        $this->assertEquals(0.6667, round($metrics['success_rate'], 4));
        $this->assertEquals(0.3333, round($metrics['error_rate'], 4));
        $this->assertGreaterThan(0, $metrics['response_time']['avg_ms']);
        $this->assertEquals(500, $metrics['tokens']['average']);
    }

    /**
     * Test alert checking
     */
    public function test_check_alerts(): void
    {
        $user = User::factory()->create();

        // Create many error logs to trigger high error rate alert
        for ($i = 0; $i < 10; $i++) {
            ChatbotLoggingService::logRequest(
                userId: $user->id,
                userMessage: "Message $i",
                status: $i < 1 ? 'success' : 'error',
                errorCode: $i < 1 ? null : 'GEMINI_API_ERROR',
                responseTimeMs: 1000
            );
        }

        $alerts = ChatbotLoggingService::checkAlerts(60);

        // Should have at least one alert (high error rate)
        $this->assertGreaterThan(0, count($alerts));

        $alertTypes = array_map(fn($a) => $a['type'], $alerts);
        $this->assertContains('HIGH_ERROR_RATE', $alertTypes);
    }

    /**
     * Test sampling configuration
     */
    public function test_logging_respects_sampling_rate(): void
    {
        config(['monitoring.chatbot.sampling.enabled' => true]);
        config(['monitoring.chatbot.sampling.rate' => 0.1]); // Only 10% sampling

        $user = User::factory()->create();

        // Try to log many times
        for ($i = 0; $i < 100; $i++) {
            ChatbotLoggingService::logRequest(
                userId: $user->id,
                userMessage: "Message $i",
                status: 'success',
                responseTimeMs: 100
            );
        }

        $logCount = ChatbotLog::count();

        // Should have logged approximately 10% (with some variance)
        $this->assertLessThan(50, $logCount);
        $this->assertGreaterThan(0, $logCount);
    }

    /**
     * Test cleanup old logs
     */
    public function test_cleanup_old_logs(): void
    {
        $user = User::factory()->create();

        // Create a log
        $log = ChatbotLog::create([
            'user_id' => $user->id,
            'request_id' => \Illuminate\Support\Str::uuid()->toString(),
            'user_message' => 'Test',
            'status' => 'success',
            'response_time_ms' => 100,
            'created_at' => now()->subDays(100), // Older than 90 days
        ]);

        $this->assertDatabaseHas('chatbot_logs', ['id' => $log->id]);

        config(['monitoring.chatbot.retention.days' => 90]);
        config(['monitoring.chatbot.retention.auto_cleanup' => true]);

        ChatbotLoggingService::cleanupOldLogs();

        $this->assertDatabaseMissing('chatbot_logs', ['id' => $log->id]);
    }
}
