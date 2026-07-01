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
        $userMessage = strtolower(trim($request->input('message')));

        // Check if Gemini API key is configured
        $apiKey = config('services.gemini.key');

        if (empty($apiKey)) {
            // Fallback: rule-based responses when AI service not configured
            $reply = $this->getFallbackReply($userMessage, $user);
            return $this->success(['reply' => $reply], 'OK', 200);
        }

        // Fetch last order to provide context
        $lastOrder = Order::where('customer_id', $user->id)->latest('created_at')->first();

        $systemPrompt = "Kamu adalah asisten Customer Service berpengalaman untuk platform TukangDekat, aplikasi pemesanan jasa lokal di Kecamatan Bojongloa Kaler. Bantu user dengan ramah jika menemui kendala transaksi.";

        if ($lastOrder) {
            $systemPrompt .= sprintf(" Pengguna memiliki pesanan terakhir: kode=%s, status=%s.", $lastOrder->order_code ?? 'N/A', $lastOrder->status ?? 'N/A');
        }

        $model = config('services.gemini.model', 'gemini-pro');
        $base = rtrim(config('services.gemini.endpoint', 'https://generativelanguage.googleapis.com/v1beta'), '/');
        $url = sprintf('%s/models/%s:generateContent?key=%s', $base, $model, $apiKey);

        $payload = [
            'contents' => [
                ['role' => 'user', 'parts' => [['text' => $systemPrompt . "\n\nUser: " . $request->input('message')]]],
            ],
            'generationConfig' => [
                'temperature' => 0.2,
                'maxOutputTokens' => 1024,
            ],
        ];

        try {
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
            ])->timeout(15)->post($url, $payload);

            if ($response->failed()) {
                $reply = $this->getFallbackReply($userMessage, $user);
                return $this->success(['reply' => $reply], 'OK', 200);
            }

            $body = $response->json();

            $reply = null;
            if (isset($body['candidates'][0]['content']['parts'][0]['text'])) {
                $reply = $body['candidates'][0]['content']['parts'][0]['text'];
            } elseif (isset($body['candidates'][0]['content']['text'])) {
                $reply = $body['candidates'][0]['content']['text'];
            }

            if (empty($reply)) {
                $reply = $this->getFallbackReply($userMessage, $user);
            }

            return $this->success(['reply' => $reply], 'OK', 200);
        } catch (\Exception $e) {
            $reply = $this->getFallbackReply($userMessage, $user);
            return $this->success(['reply' => $reply], 'OK', 200);
        }
    }

    private function getFallbackReply(string $message, $user): string
    {
        $lastOrder = Order::where('customer_id', $user->id)->latest('created_at')->first();

        if (str_contains($message, 'status') || str_contains($message, 'pesanan') || str_contains($message, 'order')) {
            if ($lastOrder) {
                return "Pesanan terakhir Anda ({$lastOrder->order_code}) saat ini berstatus: {$lastOrder->status}. Silakan cek halaman 'Pesanan' untuk detail lebih lanjut.";
            }
            return "Anda belum memiliki pesanan. Silakan cari teknisi di halaman Beranda untuk membuat pesanan baru.";
        }

        if (str_contains($message, 'bayar') || str_contains($message, 'payment') || str_contains($message, 'qris')) {
            return "Pembayaran di TukangDekat menggunakan sistem DP 50% + Pelunasan 50%. Setelah order diterima teknisi, Anda bisa membayar DP melalui QRIS. Pelunasan dilakukan setelah pekerjaan selesai.";
        }

        if (str_contains($message, 'batal') || str_contains($message, 'cancel')) {
            return "Untuk membatalkan pesanan, silakan hubungi admin melalui halaman pesanan. Pembatalan hanya bisa dilakukan sebelum teknisi memulai pekerjaan.";
        }

        if (str_contains($message, 'halo') || str_contains($message, 'hai') || str_contains($message, 'hi') || str_contains($message, 'hello')) {
            return "Halo! Saya asisten TukangDekat. Ada yang bisa saya bantu? Anda bisa bertanya tentang status pesanan, pembayaran, atau layanan kami.";
        }

        return "Terima kasih telah menghubungi TukangDekat! Saya bisa membantu Anda dengan:\n- Cek status pesanan\n- Informasi pembayaran\n- Cara memesan jasa\n- Pembatalan pesanan\n\nSilakan tanyakan sesuai kebutuhan Anda.";
    }
}
