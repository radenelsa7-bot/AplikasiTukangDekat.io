<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Traits\ApiResponse;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
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
    $userMessage = (string) $request->input('message');

    // Fetch last order to provide context
    $lastOrder = Order::where('customer_id', $user->id)->latest('created_at')->first();

    $reply = $this->tryGeminiReply($userMessage, $lastOrder);

    // Whenever the AI provider is not configured or fails, fall back to a
    // helpful rule-based answer so the assistant always responds.
    if ($reply === null) {
      $reply = $this->fallbackReply($userMessage, $lastOrder);
    }

    return $this->success(['reply' => $reply], 'OK', 200);
  }

  private function tryGeminiReply(string $userMessage, ?Order $lastOrder): ?string
  {
    $key = config('services.gemini.key');
    $endpoint = config('services.gemini.endpoint');
    $model = config('services.gemini.model');

    if (empty($key) || empty($endpoint) || empty($model)) {
      return null;
    }

    $systemPrompt = $this->systemPrompt($lastOrder);
    $base = rtrim($endpoint, '/');
    $url = sprintf('%s/models/%s:generateMessage', $base, $model);

    $payload = [
      'messages' => [
        ['role' => 'system', 'content' => ['text' => $systemPrompt]],
        ['role' => 'user', 'content' => ['text' => $userMessage]],
      ],
      'temperature' => 0.2,
    ];

    try {
      $response = Http::timeout(15)->withHeaders([
        'Authorization' => 'Bearer ' . $key,
        'Content-Type' => 'application/json',
      ])->post($url, $payload);

      if ($response->failed()) {
        Log::warning('Chatbot AI provider returned an error', [
          'status' => $response->status(),
        ]);
        return null;
      }

      $body = $response->json();

      if (isset($body['candidates'][0]['content']['text'])) {
        return $body['candidates'][0]['content']['text'];
      }

      if (isset($body['output'][0]['content'][0]['text'])) {
        return $body['output'][0]['content'][0]['text'];
      }

      return null;
    } catch (\Throwable $e) {
      Log::warning('Chatbot AI provider request failed', [
        'message' => $e->getMessage(),
      ]);
      return null;
    }
  }

  private function systemPrompt(?Order $lastOrder): string
  {
    $prompt = "Kamu adalah asisten Customer Service berpengalaman untuk platform TukangDekat, aplikasi pemesanan jasa lokal di Kecamatan Bojongloa Kaler. Bantu user dengan ramah jika menemui kendala transaksi.";

    if ($lastOrder) {
      $prompt .= sprintf(" Pengguna memiliki pesanan terakhir: kode=%s, status=%s.", $lastOrder->order_code ?? 'N/A', $lastOrder->status ?? 'N/A');
    }

    return $prompt;
  }

  /**
   * Rule-based assistant used when no AI provider is available. Handles the
   * common intents surfaced in the chatbot UI (order status, payments, how to
   * order, and cancellation).
   */
  private function fallbackReply(string $message, ?Order $lastOrder): string
  {
    $text = mb_strtolower($message);

    $mentions = static function (array $keywords) use ($text): bool {
      foreach ($keywords as $keyword) {
        if (str_contains($text, $keyword)) {
          return true;
        }
      }
      return false;
    };

    if ($mentions(['batal', 'cancel', 'pembatalan'])) {
      $reply = "Untuk membatalkan pesanan:\n"
        . "1. Buka menu 'Pesanan Saya' dan pilih pesanan yang ingin dibatalkan.\n"
        . "2. Pembatalan hanya bisa dilakukan selama pesanan belum dikerjakan (status CREATED atau ACCEPTED).\n"
        . "3. Jika DP sudah dibayar, dana akan diproses sesuai kebijakan refund.\n"
        . "Butuh bantuan lebih lanjut? Sampaikan kode pesananmu ya.";
      return $this->withOrderContext($reply, $lastOrder);
    }

    if ($mentions(['status', 'pesanan saya', 'lacak', 'progres', 'progress'])) {
      if ($lastOrder) {
        return sprintf(
          "Pesanan terakhirmu (kode %s) berstatus: %s.\n"
            . "Kamu bisa melihat detail lengkap dan riwayat status pada halaman Detail Order.",
          $lastOrder->order_code ?? 'N/A',
          $this->humanStatus($lastOrder->status)
        );
      }
      return "Saat ini belum ada pesanan yang tercatat pada akunmu. Kamu bisa memesan jasa lewat halaman utama, lalu status pesanannya akan tampil di menu 'Pesanan Saya'.";
    }

    if ($mentions(['bayar', 'pembayaran', 'dp', 'qris', 'pelunasan', 'refund', 'harga', 'biaya'])) {
      $reply = "Informasi pembayaran TukangDekat:\n"
        . "1. Pembayaran dilakukan dua tahap: DP saat pesanan diterima, dan pelunasan setelah pekerjaan selesai.\n"
        . "2. Pembayaran memakai QRIS. Buka halaman pembayaran atau scan QRIS, lalu selesaikan transaksi.\n"
        . "3. Setelah pembayaran berhasil, status pembayaran akan otomatis berubah menjadi 'Sudah dibayar'.\n"
        . "Jika status belum berubah beberapa saat setelah membayar, muat ulang halaman Detail Order.";
      return $this->withOrderContext($reply, $lastOrder);
    }

    if ($mentions(['pesan', 'order', 'memesan', 'booking', 'cara'])) {
      return "Cara memesan jasa di TukangDekat:\n"
        . "1. Pilih kategori jasa yang kamu butuhkan.\n"
        . "2. Pilih penyedia (tukang) yang tersedia di sekitarmu.\n"
        . "3. Tentukan jadwal dan tambahkan catatan kebutuhanmu.\n"
        . "4. Konfirmasi pesanan, lalu bayar DP setelah penyedia menerima pesananmu.";
    }

    if ($mentions(['halo', 'hai', 'hello', 'assalam', 'pagi', 'siang', 'sore', 'malam', 'terima kasih', 'makasih'])) {
      return "Halo! Saya asisten TukangDekat. Saya bisa membantu soal status pesanan, informasi pembayaran, cara memesan jasa, dan pembatalan pesanan. Ada yang bisa saya bantu?";
    }

    return "Maaf, saya belum sepenuhnya memahami pertanyaanmu. Saya bisa membantu tentang:\n"
      . "- Status pesanan\n"
      . "- Informasi pembayaran\n"
      . "- Cara memesan jasa\n"
      . "- Pembatalan pesanan\n"
      . "Silakan tanyakan salah satu topik di atas ya.";
  }

  private function withOrderContext(string $reply, ?Order $lastOrder): string
  {
    if ($lastOrder) {
      $reply .= sprintf(
        "\n\nPesanan terakhirmu: kode %s, status %s.",
        $lastOrder->order_code ?? 'N/A',
        $this->humanStatus($lastOrder->status)
      );
    }

    return $reply;
  }

  private function humanStatus(?string $status): string
  {
    return match (strtoupper((string) $status)) {
      'CREATED' => 'Menunggu konfirmasi penyedia (CREATED)',
      'ACCEPTED' => 'Diterima penyedia, menunggu pembayaran DP (ACCEPTED)',
      'IN_PROGRESS' => 'Sedang dikerjakan (IN_PROGRESS)',
      'COMPLETED' => 'Pekerjaan selesai, menunggu pelunasan (COMPLETED)',
      'CLOSED' => 'Selesai dan lunas (CLOSED)',
      'CANCELLED' => 'Dibatalkan (CANCELLED)',
      default => $status ?? 'N/A',
    };
  }
}
