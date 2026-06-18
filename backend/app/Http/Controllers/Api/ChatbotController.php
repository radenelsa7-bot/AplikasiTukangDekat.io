<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Traits\ApiResponse;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Http\JsonResponse;

class ChatbotController extends Controller
{
  use ApiResponse;

  public function sendMessage(Request $request): JsonResponse
  {
    $request->validate([
      'message' => 'required|string|max:2000',
    ]);

    $user = $request->user();

    // Fetch last order to provide context
    $lastOrder = Order::where('customer_id', $user->id)->latest('created_at')->first();

    $systemPrompt = "Kamu adalah asisten Customer Service berpengalaman untuk platform TukangDekat, aplikasi pemesanan jasa lokal di Kecamatan Bojongloa Kaler. Bantu user dengan ramah jika menemui kendala transaksi.";

    if ($lastOrder) {
      $systemPrompt .= sprintf(" Pengguna memiliki pesanan terakhir: kode=%s, status=%s.", $lastOrder->order_code ?? 'N/A', $lastOrder->status ?? 'N/A');
    }

    $userMessage = $request->input('message');

    $model = config('services.gemini.model');
    $base = rtrim(config('services.gemini.endpoint'), '/');
    $url = sprintf('%s/models/%s:generateMessage', $base, $model);

    $payload = [
      'messages' => [
        ['role' => 'system', 'content' => ['text' => $systemPrompt]],
        ['role' => 'user', 'content' => ['text' => $userMessage]],
      ],
      'temperature' => 0.2,
    ];

    try {
      $response = Http::withHeaders([
        'Authorization' => 'Bearer ' . config('services.gemini.key'),
        'Content-Type' => 'application/json',
      ])->post($url, $payload);

      if ($response->failed()) {
        return $this->error('AI service error', 500, ['details' => $response->body()]);
      }

      $body = $response->json();

      // Try to extract a reply text from common Gemini response shapes
      $reply = null;
      if (isset($body['candidates'][0]['content']['text'])) {
        $reply = $body['candidates'][0]['content']['text'];
      } elseif (isset($body['output'][0]['content'][0]['text'])) {
        $reply = $body['output'][0]['content'][0]['text'];
      } else {
        $reply = $response->body();
      }

      return $this->success(['reply' => $reply], 'OK', 200);
    } catch (\Exception $e) {
      return $this->error('Failed to contact AI service', 500, ['exception' => $e->getMessage()]);
    }
  }
}
