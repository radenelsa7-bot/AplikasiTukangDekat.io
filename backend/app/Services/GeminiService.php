<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiService
{
    protected string $endpoint;
    protected string $apiKey;
    protected string $model;

    public function __construct()
    {
        $this->endpoint = config('services.gemini.endpoint');
        $this->apiKey = config('services.gemini.api_key');
        $this->model = config('services.gemini.model', 'gemini-1.0');
    }

    public function isConfigured(): bool
    {
        return !empty($this->endpoint) && !empty($this->apiKey);
    }

    /**
     * Send messages to Gemini and return assistant text.
     * Returns detailed response including metrics for logging.
     * Throws \RuntimeException on permanent failures.
     */
    public function send(array $messages, int $maxTokens = 512): array
    {
        if (!$this->isConfigured()) {
            throw new \RuntimeException('Gemini not configured');
        }

        $payload = [
            'model' => $this->model,
            'messages' => $messages,
            'max_tokens' => $maxTokens,
        ];

        $attempts = config('chatbot.gemini_retry.times', 3);
        $baseSleep = config('chatbot.gemini_retry.base_sleep_ms', 200);

        $lastException = null;
        $startTime = microtime(true);
        $retryCount = 0;

        for ($i = 0; $i < $attempts; $i++) {
            try {
                $attemptStartTime = microtime(true);

                $response = Http::timeout(30)
                    ->acceptJson()
                    ->withHeaders([
                        'Authorization' => 'Bearer ' . $this->apiKey,
                        'Content-Type' => 'application/json',
                    ])
                    ->post($this->endpoint, $payload);

                $attemptTime = (microtime(true) - $attemptStartTime) * 1000; // ms

                if (!$response->successful()) {
                    Log::warning('Gemini API returned non-success status', [
                        'status' => $response->status(),
                        'attempt' => $i + 1,
                        'response_time_ms' => $attemptTime,
                    ]);
                    
                    // Retry on 5xx
                    if ($response->serverError() && $i + 1 < $attempts) {
                        $retryCount++;
                        $sleepTime = $baseSleep * (2 ** $i);
                        usleep($sleepTime * 1000);
                        continue;
                    }

                    $totalTime = (microtime(true) - $startTime) * 1000;

                    return [
                        'error' => true,
                        'status' => $response->status(),
                        'body' => $response->json(),
                        'response_time_ms' => (int)$totalTime,
                        'retry_count' => $retryCount,
                    ];
                }

                $apiData = $response->json();

                // Support multiple possible Gemini response shapes
                $assistantMessage = $apiData['choices'][0]['message']['content'] ?? $apiData['output'][0]['content'][0]['text'] ?? null;

                if (!$assistantMessage) {
                    Log::warning('Gemini API returned unexpected format', [
                        'response' => $apiData,
                        'attempt' => $i + 1,
                    ]);
                    
                    $totalTime = (microtime(true) - $startTime) * 1000;

                    return [
                        'error' => true,
                        'status' => 502,
                        'body' => $apiData,
                        'code' => 'GEMINI_RESPONSE_INVALID',
                        'response_time_ms' => (int)$totalTime,
                        'retry_count' => $retryCount,
                    ];
                }

                $totalTime = (microtime(true) - $startTime) * 1000;

                // Extract token usage if available
                $tokensUsed = null;
                if (isset($apiData['usage'])) {
                    $tokensUsed = ($apiData['usage']['input_tokens'] ?? 0) + ($apiData['usage']['output_tokens'] ?? 0);
                }

                return [
                    'error' => false,
                    'assistant' => $assistantMessage,
                    'raw' => $apiData,
                    'response_time_ms' => (int)$totalTime,
                    'retry_count' => $retryCount,
                    'tokens_used' => $tokensUsed,
                ];
            } catch (\Throwable $e) {
                $lastException = $e;
                $totalTime = (microtime(true) - $startTime) * 1000;

                Log::error('Gemini request exception', [
                    'message' => $e->getMessage(),
                    'attempt' => $i + 1,
                    'response_time_ms' => (int)$totalTime,
                ]);

                if ($i + 1 < $attempts) {
                    $retryCount++;
                    $sleepTime = $baseSleep * (2 ** $i);
                    usleep($sleepTime * 1000);
                    continue;
                }
                break;
            }
        }

        $totalTime = (microtime(true) - $startTime) * 1000;

        throw new \RuntimeException('Gemini request failed: ' . ($lastException ? $lastException->getMessage() : 'unknown'));
    }
}
