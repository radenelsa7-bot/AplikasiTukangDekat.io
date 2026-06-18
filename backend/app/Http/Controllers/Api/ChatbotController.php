<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ChatbotRequest;
use App\Models\Order;
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

        $lastOrder = Order::where('customer_id', $user->id)
            ->latest('created_at')
            ->first();

        $orderContext = $lastOrder ? sprintf(
            "Pesanan terakhir Anda: kode %s, status %s, alamat %s, harga estimasi %s.",
            $lastOrder->order_code,
            $lastOrder->status,
            $lastOrder->address,
            $lastOrder->estimated_price !== null ? 'Rp ' . number_format($lastOrder->estimated_price, 0, ',', '.') : 'tidak tersedia'
        ) : 'Tidak ada riwayat pesanan terakhir untuk pengguna ini.';

        $systemPrompt = "Kamu adalah asisten Customer Service berpengalaman untuk platform TukangDekat, aplikasi pemesanan jasa lokal di Kecamatan Bojongloa Kaler. Bantu user dengan ramah jika menemui kendala transaksi.";

        $payload = [
            'model' => config('services.gemini.model', 'gemini-1.0'),
            'messages' => [
                ['role' => 'system', 'content' => $systemPrompt],
                ['role' => 'system', 'content' => $orderContext],
                ['role' => 'user', 'content' => $validated['message']],
            ],
            'max_tokens' => 512,
        ];

        $geminiUrl = config('services.gemini.endpoint');
        $geminiKey = config('services.gemini.api_key');

        if (!$geminiUrl || !$geminiKey) {
            return $this->error('Gemini API is not configured.', 500, 'GEMINI_NOT_CONFIGURED');
        }

        try {
            $response = Http::timeout(30)
                ->acceptJson()
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $geminiKey,
                    'Content-Type' => 'application/json',
                ])
                ->post($geminiUrl, $payload);

            if (!$response->successful()) {
                Log::error('Gemini API request failed', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                return $this->error('Failed to contact Gemini API', 502, 'GEMINI_API_ERROR', [
                    'status' => $response->status(),
                    'response' => $response->json(),
                ]);
            }

            $apiData = $response->json();
            $assistantMessage = $apiData['choices'][0]['message']['content'] ?? $apiData['output'][0]['content'][0]['text'] ?? null;

            if (!$assistantMessage) {
                Log::warning('Gemini API returned unexpected response format', ['response' => $apiData]);
                return $this->error('Gemini API did not return a valid assistant response.', 502, 'GEMINI_RESPONSE_INVALID');
            }

            return $this->success([
                'user_message' => $validated['message'],
                'assistant_message' => $assistantMessage,
                'order_context' => $orderContext,
                'raw_response' => $apiData,
            ], 'Chatbot response received');
        } catch (\Throwable $e) {
            Log::error('Chatbot sendMessage error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->internalServerError('Unable to process chatbot request');
        }
    }
}
