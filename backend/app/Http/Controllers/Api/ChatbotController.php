<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ChatbotRequest;
use App\Models\Order;
use App\Models\ChatMessage;
use App\Services\GeminiService;
use App\Services\ChatbotLoggingService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ChatbotController extends Controller
{
    use ApiResponse;

    public function sendMessage(ChatbotRequest $request): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validated();

        $orderCount = (int) config('chatbot.order_context_count', 1);
        $orders = Order::where('customer_id', $user->id)
            ->latest('created_at')
            ->take($orderCount)
            ->get();

        if ($orders->isEmpty()) {
            $orderContext = 'Tidak ada riwayat pesanan terakhir untuk pengguna ini.';
            $orderId = null;
        } else {
            $parts = [];
            foreach ($orders as $o) {
                $parts[] = sprintf(
                    "kode %s (status %s, alamat %s, harga %s)",
                    $o->order_code,
                    $o->status,
                    $o->address,
                    $o->estimated_price !== null ? 'Rp ' . number_format($o->estimated_price, 0, ',', '.') : 'tidak tersedia'
                );
            }
            $orderContext = 'Pesanan terbaru: ' . implode('; ', $parts);
            $orderId = $orders->first()->id;
        }

        $systemPrompt = "Kamu adalah asisten Customer Service berpengalaman untuk platform TukangDekat, aplikasi pemesanan jasa lokal di Kecamatan Bojongloa Kaler. Bantu user dengan ramah jika menemui kendala transaksi.";

        $messages = [
            ['role' => 'system', 'content' => $systemPrompt],
            ['role' => 'system', 'content' => $orderContext],
            ['role' => 'user', 'content' => $validated['message']],
        ];

        $gemini = app(GeminiService::class);

        if (!$gemini->isConfigured()) {
            return $this->error('Gemini API is not configured.', 500, 'GEMINI_NOT_CONFIGURED');
        }

        // persist user message
        try {
            ChatMessage::create([
                'user_id' => $user->id,
                'order_id' => $orderId,
                'role' => 'user',
                'message' => $validated['message'],
            ]);
        } catch (\Throwable $e) {
            Log::warning('Failed to persist user chat message', ['err' => $e->getMessage()]);
        }

        try {
            $result = $gemini->send($messages, 512);

            if (isset($result['error']) && $result['error'] === true) {
                $status = $result['status'] ?? 502;
                $details = $result['body'] ?? null;
                $responseTimeMs = $result['response_time_ms'] ?? 0;
                $retryCount = $result['retry_count'] ?? 0;

                Log::error('Gemini service returned error', [
                    'status' => $status,
                    'details' => $details,
                    'response_time_ms' => $responseTimeMs,
                ]);

                // Log error to chatbot logs
                ChatbotLoggingService::logRequest(
                    userId: $user->id,
                    userMessage: $validated['message'],
                    status: 'error',
                    responseTimeMs: $responseTimeMs,
                    errorCode: $result['code'] ?? 'GEMINI_API_ERROR',
                    errorMessage: 'Gemini API returned error: ' . $status,
                    retryCount: $retryCount,
                    orderContext: [
                        'order_count' => $orders->count(),
                        'order_context' => $orderContext,
                    ]
                );

                if (isset($result['code']) && $result['code'] === 'GEMINI_RESPONSE_INVALID') {
                    return $this->error('Gemini API did not return a valid assistant response.', 502, 'GEMINI_RESPONSE_INVALID');
                }

                return $this->error('Failed to contact Gemini API', 502, 'GEMINI_API_ERROR', ['status' => $status, 'response' => $details]);
            }

            $assistantMessage = $result['assistant'] ?? null;
            $raw = $result['raw'] ?? null;
            $responseTimeMs = $result['response_time_ms'] ?? 0;
            $retryCount = $result['retry_count'] ?? 0;
            $tokensUsed = $result['tokens_used'] ?? null;

            if (!$assistantMessage) {
                Log::warning('Gemini returned no assistant message', ['raw' => $raw]);

                ChatbotLoggingService::logRequest(
                    userId: $user->id,
                    userMessage: $validated['message'],
                    status: 'error',
                    responseTimeMs: $responseTimeMs,
                    errorCode: 'GEMINI_RESPONSE_INVALID',
                    errorMessage: 'Gemini did not return valid assistant message',
                    retryCount: $retryCount,
                    tokensUsed: $tokensUsed,
                    orderContext: [
                        'order_count' => $orders->count(),
                        'order_context' => $orderContext,
                    ]
                );

                return $this->error('Gemini API did not return a valid assistant response.', 502, 'GEMINI_RESPONSE_INVALID');
            }

            // persist assistant message with raw response
            try {
                ChatMessage::create([
                    'user_id' => $user->id,
                    'order_id' => $orderId,
                    'role' => 'assistant',
                    'message' => $assistantMessage,
                    'raw_response' => $raw,
                ]);
            } catch (\Throwable $e) {
                Log::warning('Failed to persist assistant chat message', ['err' => $e->getMessage()]);
            }

            // Log successful request
            ChatbotLoggingService::logRequest(
                userId: $user->id,
                userMessage: $validated['message'],
                status: 'success',
                assistantMessage: $assistantMessage,
                orderContext: [
                    'order_count' => $orders->count(),
                    'order_context' => $orderContext,
                ],
                responseTimeMs: $responseTimeMs,
                retryCount: $retryCount,
                tokensUsed: $tokensUsed,
                metadata: [
                    'order_id' => $orderId,
                ]
            );

            $response = $this->success([
                'user_message' => $validated['message'],
                'assistant_message' => $assistantMessage,
                'order_context' => $orderContext,
                'raw_response' => $raw,
            ], 'Chatbot response received');

            // Add helpful rate-limit headers (informational)
            $response->headers->set('X-RateLimit-Limit', config('chatbot.rate_limit.limit'));
            $response->headers->set('X-RateLimit-Period', config('chatbot.rate_limit.period'));

            return $response;
        } catch (\Throwable $e) {
            Log::error('Chatbot sendMessage error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            // Log exception
            ChatbotLoggingService::logRequest(
                userId: $user->id,
                userMessage: $validated['message'],
                status: 'error',
                errorCode: 'INTERNAL_ERROR',
                errorMessage: $e->getMessage(),
                orderContext: [
                    'order_count' => $orders->count(),
                    'order_context' => $orderContext,
                ]
            );

            return $this->internalServerError('Unable to process chatbot request', 'GEMINI_API_ERROR');
        }
    }
}
