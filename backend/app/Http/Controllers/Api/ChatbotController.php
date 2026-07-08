<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Traits\ApiResponse;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
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

    // If provider not available or returned nothing, try local docs-based reply
    if ($reply === null) {
      $docReply = $this->localDocReply($userMessage, $lastOrder);
      if ($docReply !== null) {
        $reply = $docReply;
      }
    }

    // Whenever the AI provider and local docs fail, fall back to a
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
    // Attach short relevant document context from `docs/` to improve knowledge
    $docContext = $this->getDocContext($userMessage);
    if (!empty($docContext)) {
      $systemPrompt = $systemPrompt . "\n\nRELEVANT DOCUMENTS:\n" . $docContext;
    }
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

      // Try robust extraction of text from multiple possible fields
      $body = null;
      try {
        $body = $response->json();
      } catch (\Throwable $e) {
        $body = null;
      }

      $textCandidate = null;
      if (is_array($body)) {
        // Common Google/Anthropic-like structures
        if (isset($body['candidates'][0]['content']['text'])) {
          $textCandidate = $body['candidates'][0]['content']['text'];
        } elseif (isset($body['output'][0]['content'][0]['text'])) {
          $textCandidate = $body['output'][0]['content'][0]['text'];
        } elseif (isset($body['choices'][0]['message']['content'][0]['text'])) {
          $textCandidate = $body['choices'][0]['message']['content'][0]['text'];
        } elseif (isset($body['choices'][0]['text'])) {
          $textCandidate = $body['choices'][0]['text'];
        } elseif (isset($body['message']['content'])) {
          // Some providers return nested content arrays
          if (is_array($body['message']['content'])) {
            foreach ($body['message']['content'] as $c) {
              if (is_array($c) && isset($c['text'])) {
                $textCandidate = $c['text'];
                break;
              }
            }
          } elseif (is_string($body['message']['content'])) {
            $textCandidate = $body['message']['content'];
          }
        }
      }

      // Fallback to raw body string
      if ($textCandidate === null) {
        try {
          $raw = $response->body();
          if (!empty($raw)) {
            // If it looks like JSON, try decoding and extracting 'reply'
            $maybe = json_decode($raw, true);
            if (is_array($maybe) && isset($maybe['reply'])) {
              return (string) $maybe['reply'];
            }
            // If it's plain text, use it
            $textCandidate = trim($raw);
          }
        } catch (\Throwable $_) {
          // ignore
        }
      }

      if (is_string($textCandidate) && $textCandidate !== '') {
        // If model returned JSON string, try to parse 'reply' field
        $decoded = json_decode($textCandidate, true);
        if (is_array($decoded) && isset($decoded['reply'])) {
          return (string) $decoded['reply'];
        }
        return $textCandidate;
      }

      return null;
    } catch (\Throwable $e) {
      Log::warning('Chatbot AI provider request failed', [
        'message' => $e->getMessage(),
      ]);
      return null;
    }
  }

  /**
   * Generate a local reply from docs when LLM isn't available.
   * This function attempts a short extractive summary in Indonesian and avoids
   * returning raw document text or filenames.
   */
  private function localDocReply(string $userMessage, ?Order $lastOrder): ?string
  {
    try {
      $context = $this->getDocContext($userMessage, 6);
      if (empty($context)) return null;

      // Clean the context from noise such as URLs, API paths, code-like fragments,
      // and markdown list markers before summarizing.
      $cleanContext = preg_replace('/https?:\/\/\S+/', ' ', $context);
      $cleanContext = preg_replace('/`[^`]*`/', ' ', $cleanContext);
      $cleanContext = preg_replace('/\bPOST\s+\/api\/\S+/i', ' ', $cleanContext);
      $cleanContext = preg_replace('/\bGET\s+\/api\/\S+/i', ' ', $cleanContext);
      $cleanContext = preg_replace('/\bPATCH\s+\/api\/\S+/i', ' ', $cleanContext);
      $cleanContext = preg_replace('/\bDELETE\s+\/api\/\S+/i', ' ', $cleanContext);
      $cleanContext = preg_replace('/\bPUT\s+\/api\/\S+/i', ' ', $cleanContext);
      $cleanContext = preg_replace('/[-*+>]{1,2}\s*/', ' ', $cleanContext);
      $cleanContext = preg_replace('/\s+/', ' ', trim($cleanContext));

      $sentences = preg_split('/(?<=[.!?])\s+/', $cleanContext);
      $q = strtolower($userMessage);
      $tokens = preg_split('/\W+/', $q, -1, PREG_SPLIT_NO_EMPTY);
      $domainTerms = ['order', 'pesanan', 'pembayaran', 'qris', 'tagihan', 'invoice', 'nota', 'provider', 'pelanggan', 'fitur', 'registrasi', 'login', 'status', 'pesan', 'bayar', 'batal', 'cancel', 'refund', 'penyedia', 'akun', 'menu', 'tukang', 'jasa'];

      $hasDomainQuery = false;
      foreach ($tokens as $token) {
        if (strlen($token) < 3) continue;
        foreach ($domainTerms as $term) {
          if ($token === $term || str_contains($token, $term) || str_contains($term, $token)) {
            $hasDomainQuery = true;
            break 2;
          }
        }
      }

      if (! $hasDomainQuery) {
        return null;
      }

      $picked = [];
      foreach ($sentences as $s) {
        $low = strtolower($s);
        foreach ($tokens as $t) {
          if (strlen($t) < 3) continue;
          if (str_contains($low, $t)) {
            $picked[] = trim($s);
            break;
          }
        }
        if (count($picked) >= 6) break;
      }

      if (empty($picked)) {
        // If no sentence matches query tokens, try broader match on application-specific terms
        foreach ($sentences as $s) {
          $low = strtolower($s);
          foreach ($domainTerms as $term) {
            if (str_contains($low, $term)) {
              $picked[] = trim($s);
              break;
            }
          }
          if (count($picked) >= 4) break;
        }
      }

      if (empty($picked)) {
        return null;
      }

      $answer = $this->buildSimpleDocAnswer($userMessage, $picked, $lastOrder);
      return $answer;
    } catch (\Throwable $e) {
      Log::warning('localDocReply failed', ['error' => $e->getMessage()]);
      return null;
    }
  }

  private function buildSimpleDocAnswer(string $userMessage, array $sentences, ?Order $lastOrder): string
  {
    $text = strtolower($userMessage);
    $contains = function (array $words) use ($text): bool {
      foreach ($words as $word) {
        if (str_contains($text, $word)) {
          return true;
        }
      }
      return false;
    };

    if ($contains(['cara memesan', 'memesan tukang', 'pesan tukang', 'cara pesan', 'order jasa', 'buat order'])) {
      $reply = "Untuk memesan jasa di TukangDekat:
1. Pilih kategori layanan yang dibutuhkan.
2. Pilih tukang atau penyedia yang tersedia.
3. Isi detail jadwal, alamat, dan catatan pekerjaan.
4. Konfirmasi pesanan dan lanjutkan ke pembayaran.
Setelah pesanan dibuat, Anda dapat melihat statusnya di menu Pesanan Saya.";
    } elseif ($contains(['pembayaran', 'qris', 'dp', 'pelunasan', 'bayar'])) {
      $reply = "Alur pembayaran di TukangDekat biasanya:
1. Setelah pesanan dibuat dan diterima, sistem menyiapkan pembayaran.
2. Anda akan menerima informasi QRIS untuk membayar DP atau pelunasan.
3. Scan QRIS dengan aplikasi pembayaran Anda.
4. Setelah pembayaran berhasil, status pesanan akan diperbarui otomatis.";
    } elseif ($contains(['batal', 'pembatalan', 'batalkan', 'cancel'])) {
      $reply = "Pembatalan pesanan di TukangDekat biasanya dapat dilakukan sebelum pekerjaan dimulai.
1. Buka halaman Pesanan Saya.
2. Pilih pesanan yang ingin dibatalkan.
3. Ajukan pembatalan dari detail pesanan.
Jika DP sudah dibayar, pengembalian dana akan diproses sesuai kebijakan refund.";
    } elseif ($contains(['fitur', 'fitur yang tersedia', 'apa saja fitur', 'pelanggan', 'pengguna'])) {
      $reply = "Fitur utama TukangDekat untuk pelanggan meliputi:
- Daftar dan login akun.
- Cari kategori layanan dan pilih tukang.
- Buat pesanan dengan jadwal dan catatan.
- Bayar menggunakan QRIS.
- Pantau status pesanan dan riwayat pesanan.
- Batalkan pesanan jika diperlukan.";
    } elseif ($contains(['login', 'registrasi', 'daftar', 'lupa password'])) {
      $reply = "Untuk masuk ke aplikasi, gunakan email dan password Anda.
Jika belum punya akun, silakan daftar terlebih dahulu sebagai pelanggan.
Setelah login, Anda bisa memesan jasa dan melihat status pesanan.
Fitur lupa password akan membantu Anda membuat ulang kata sandi jika perlu.";
    } elseif ($contains(['tagihan', 'invoice', 'nota', 'billing'])) {
      $reply = "Tagihan di TukangDekat dibuat setelah pesanan diterima dan sebelum pekerjaan dimulai.
1. Sistem akan membuat tagihan DP sebesar 50% dari estimasi harga.
2. Anda dapat melihat detail tagihan di halaman Pesanan Saya.
3. Pembayaran dilakukan melalui QRIS.
4. Setelah pembayaran diselesaikan, status tagihan akan berubah menjadi 'Lunas'.";
    } else {
      // Build a safer summary from relevant sentences without raw docs
      $summary = [];
      foreach ($sentences as $sentence) {
        $clean = preg_replace('/[\[\]{}<>`]/', '', $sentence);
        $clean = preg_replace('/\s+/', ' ', trim($clean));
        $low = strtolower($clean);
        if ($clean === '') {
          continue;
        }
        if (Str::contains($low, ['order', 'pesanan', 'pembayaran', 'qris', 'tagihan', 'provider', 'pelanggan', 'fitur', 'registrasi', 'login', 'status'])) {
          $summary[] = $clean;
        }
      }

      if (empty($summary)) {
        return 'Maaf, saya belum menemukan informasi tersebut pada dokumentasi aplikasi.';
      }

      $summary = array_unique($summary);
      $reply = "Menurut dokumentasi TukangDekat, yang saya temukan adalah: ";
      $reply .= implode(' ', array_slice($summary, 0, 2));
      $reply .= "\n\nJika masih belum jelas, coba tanyakan lagi dengan kata kunci seperti 'order', 'pembayaran', 'status pesanan', atau 'fitur'.";
    }

    if ($lastOrder) {
      $reply .= sprintf("\n\nPesanan terakhir Anda: kode %s, status %s.", $lastOrder->order_code ?? 'N/A', $this->humanStatus($lastOrder->status));
    }

    return $reply;
  }

  private function asCustomerServiceReply(string $text, ?Order $lastOrder): string
  {
    $reply = trim($text);
    if ($lastOrder) {
      $reply .= sprintf("\n\nKalau mau, saya juga bisa cek status pesanan terakhir Anda: kode %s.", $lastOrder->order_code ?? 'N/A');
    }
    return $reply;
  }

  /**
   * Build a small retrieval index from the /docs folder and return the most
   * relevant chunks for the query. Behavior:
   * - Support .md, .txt, .rst, .html, .htm, .json
   * - Split documents into chunks (approx. 700-1200 chars)
   * - Precompute simple TF vectors per chunk and cache the index
   * - Score chunks using a TF-IDF-like similarity and return top N chunks
   * Notes: returned context contains only cleaned plaintext snippets (no
   * file names, no raw markdown) to be attached to the prompt.
   */
  private function getDocContext(string $query, int $limit = 3): string
  {
    try {
      $rootDocs = base_path('docs');
      $workspaceDocs = dirname(base_path()) . DIRECTORY_SEPARATOR . 'docs';
      $allowedSubdirs = ['api', 'srs', 'testing', 'postman'];
      $docDirs = [];
      foreach ([$rootDocs, $workspaceDocs] as $docsPath) {
        foreach ($allowedSubdirs as $subdir) {
          $path = $docsPath . DIRECTORY_SEPARATOR . $subdir;
          if (File::exists($path) && File::isDirectory($path)) {
            $real = realpath($path);
            if ($real !== false && !in_array($real, $docDirs, true)) {
              $docDirs[] = $real;
            }
          }
        }
      }
      if (empty($docDirs)) {
        return '';
      }

      // Cache the processed index (chunks + term stats) to avoid reparsing files
      $indexKey = 'chatbot_docs_index_v1';
      $ttlSeconds = 600; // 10 minutes

      $index = Cache::remember($indexKey, now()->addSeconds($ttlSeconds), function () use ($docDirs) {
        $supported = ['md', 'txt', 'rst', 'html', 'htm', 'json'];
        $chunks = [];

        foreach ($docDirs as $docsDir) {
          $files = File::allFiles($docsDir);
          foreach ($files as $f) {
            $ext = strtolower(pathinfo($f->getFilename(), PATHINFO_EXTENSION));
            if (!in_array($ext, $supported)) continue;
            $raw = (string) File::get($f->getPathname());
            // If JSON, try to pull documentation-like fields
            if ($ext === 'json') {
              $maybe = json_decode($raw, true);
              if (is_array($maybe)) {
                $raw = json_encode($maybe, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
              }
            }

            // Remove markdown code blocks and HTML tags, normalize whitespace
            $clean = preg_replace('/```[\s\S]*?```/', ' ', $raw);
            $clean = strip_tags($clean);
            $clean = preg_replace('/\s+/', ' ', $clean);
            $clean = trim($clean);

            if ($clean === '') {
              continue;
            }

            // Chunk size in characters
            $chunkSize = 1000;
            $len = mb_strlen($clean);
            if ($len <= $chunkSize) {
              $chunks[] = ['text' => $clean];
              continue;
            }

            // Split into overlapping chunks to preserve sentence continuity
            $pos = 0;
            $overlap = 200;
            while ($pos < $len) {
              $chunk = mb_substr($clean, $pos, $chunkSize);
              $chunks[] = ['text' => $chunk];
              $pos += ($chunkSize - $overlap);
            }
          }
        }


        if (empty($chunks)) return ['chunks' => [], 'idf' => []];

        // Build term frequencies and document frequencies
        $stop = [];
        $docFreq = [];
        foreach ($chunks as $i => $c) {
          $text = strtolower($c['text']);
          $tokens = preg_split('/\W+/', $text, -1, PREG_SPLIT_NO_EMPTY);
          $tf = [];
          $seen = [];
          foreach ($tokens as $t) {
            if (strlen($t) < 3) continue; // ignore short tokens
            $tf[$t] = ($tf[$t] ?? 0) + 1;
            if (!isset($seen[$t])) {
              $docFreq[$t] = ($docFreq[$t] ?? 0) + 1;
              $seen[$t] = true;
            }
          }
          $chunks[$i]['tf'] = $tf;
        }

        $totalDocs = count($chunks);
        $idf = [];
        foreach ($docFreq as $term => $df) {
          $idf[$term] = log(1 + $totalDocs / (1 + $df));
        }

        return ['chunks' => $chunks, 'idf' => $idf];
      });

      if (empty($index) || empty($index['chunks'])) return '';

      // Build query vector
      $q = strtolower($query);
      $qTokens = preg_split('/\W+/', $q, -1, PREG_SPLIT_NO_EMPTY);
      $qTf = [];
      foreach ($qTokens as $t) {
        if (strlen($t) < 3) continue;
        $qTf[$t] = ($qTf[$t] ?? 0) + 1;
      }

      // Compute similarity scores (cosine of tf-idf)
      $scores = [];
      foreach ($index['chunks'] as $i => $chunk) {
        $dot = 0.0;
        $normA = 0.0;
        $normB = 0.0;
        foreach ($chunk['tf'] as $term => $tf) {
          $w = $tf * ($index['idf'][$term] ?? 0);
          $normA += $w * $w;
        }
        foreach ($qTf as $term => $tfq) {
          $wq = $tfq * ($index['idf'][$term] ?? 0);
          $normB += $wq * $wq;
          if (isset($chunk['tf'][$term])) {
            $dot += ($chunk['tf'][$term] * ($index['idf'][$term] ?? 0)) * $wq;
          }
        }
        if ($normA <= 0 || $normB <= 0) {
          $score = 0.0;
        } else {
          $score = $dot / (sqrt($normA) * sqrt($normB));
        }
        $scores[$i] = $score;
      }

      arsort($scores);
      $selected = [];
      $minScoreThreshold = 0.05;
      foreach (array_keys($scores) as $idx) {
        if (count($selected) >= $limit) break;
        if ($scores[$idx] < $minScoreThreshold) break;

        // Clean snippet: trim to sentence boundaries and avoid raw markdown
        $snippet = $index['chunks'][$idx]['text'];
        // Pick up to 2 sentences around the highest-overlap region
        $sentences = preg_split('/(?<=[.!?])\\s+/', $snippet);
        $pick = [];
        foreach ($sentences as $s) {
          $low = strtolower($s);
          foreach ($qTokens as $t) {
            if (strlen($t) < 3) continue;
            if (str_contains($low, $t)) {
              $pick[] = trim($s);
              break;
            }
          }
          if (count($pick) >= 4) break;
        }
        if (empty($pick)) {
          continue;
        }
        $selected[] = implode(' ', $pick);
      }

      // If nothing selected, return short general summary from first chunks
      if (empty($selected)) {
        return '';
      }

      // Join snippets with separators but do NOT include filenames or raw markdown
      return implode("\n\n", $selected);
    } catch (\Throwable $e) {
      Log::warning('Failed to build docs context for chatbot', ['error' => $e->getMessage()]);
      return '';
    }
  }

  private function systemPrompt(?Order $lastOrder): string
  {
    // System prompt written in Indonesian with strict rules so the model
    // answers like a customer service agent and bases replies only on docs.
    $prompt = "Anda adalah Asisten Resmi aplikasi TukangDekat. "
      . "Jawaban harus berdasarkan dokumentasi aplikasi dari folder /docs, dan hanya dari sana. "
      . "Jika informasi tidak jelas atau tidak ditemukan, katakan jujur bahwa informasi tersebut tidak ada di dokumentasi. "
      . "Gunakan bahasa Indonesia yang sederhana, ramah, dan mudah dipahami oleh pengguna awam. "
      . "Hindari istilah teknis seperti endpoint, controller, database, file, folder, atau struktur kode kecuali jika pengguna menanyakan hal tersebut sebagai developer. "
      . "Jangan menampilkan markdown, nama file, struktur folder, source code, atau potongan kode dalam jawaban. "
      . "Jangan mengutip dokumen secara mentah; jelaskan kembali isi dokumentasi dengan gaya customer service. ";

    if ($lastOrder) {
      $prompt .= sprintf("Pengguna memiliki pesanan terakhir: kode=%s, status=%s. ", $lastOrder->order_code ?? 'N/A', $lastOrder->status ?? 'N/A');
    }

    $prompt .= "\n\nAturan keluaran (HARUS DIKEMBALIKAN SEBAGAI JSON):\n";
    $prompt .= "Kembalikan hanya sebuah objek JSON dengan kunci-kunci ini:\n";
    $prompt .= "- reply: string (teks yang akan ditampilkan kepada pengguna, bahasa Indonesia)\n";
    $prompt .= "- actions: array of action objects (opsional). Action object: {type, label, payload}\n";
    $prompt .= "Jangan mengirim teks di luar objek JSON tersebut.\n";
    $prompt .= "Gunakan jawaban yang singkat namun jelas, dengan gaya customer service yang membantu.\n";

    $prompt .= "Contoh output JSON:\n";
    $example = [
      'reply' => 'Pesanan Anda sedang diproses. Kode: ORD12345',
      'actions' => [
        ['type' => 'open_order', 'label' => 'Lihat Pesanan', 'payload' => ['order_code' => $lastOrder->order_code ?? 'ORD12345']],
      ],
    ];
    $prompt .= json_encode($example, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . "\n";

    $prompt .= "Jika informasi tidak ditemukan dalam dokumentasi, kembalikan:\n";
    $prompt .= json_encode(['reply' => 'Maaf, saya belum menemukan informasi tersebut pada dokumentasi aplikasi.'], JSON_UNESCAPED_UNICODE) . "\n";

    $prompt .= "Jangan sertakan penjelasan tentang bagaimana Anda menjawab; hanya tampilkan objek JSON.\n";

    $paymentExample = [
      'reply' => 'Pembayaran untuk pesanan ORD12345 belum selesai. Anda dapat melakukan pembayaran QRIS melalui halaman Detail Pesanan.',
      'actions' => [
        ['type' => 'open_order', 'label' => 'Lihat Pesanan', 'payload' => ['order_code' => $lastOrder->order_code ?? 'ORD12345', 'order_id' => $lastOrder->id ?? null]],
        ['type' => 'generate_qris', 'label' => 'Buat QRIS Pembayaran', 'payload' => ['payment_id' => $lastOrder->payment_id ?? null]],
      ],
    ];

    $prompt .= "Contoh pembayaran (JSON):\n" . json_encode($paymentExample, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . "\n";

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

    if ($mentions(['bayar', 'pembayaran', 'dp', 'qris', 'pelunasan', 'refund', 'harga', 'biaya', 'tagihan', 'invoice', 'nota'])) {
      $reply = "Informasi pembayaran TukangDekat:\n"
        . "1. Tagihan DP dibuat setelah pesanan diterima, biasanya sebesar 50% dari estimasi harga.\n"
        . "2. Pembayaran dilakukan melalui QRIS. Buka halaman Pesanan Saya untuk melihat detail tagihan dan QRIS.\n"
        . "3. Setelah pembayaran berhasil, status pembayaran akan berubah menjadi 'Sudah dibayar'.\n"
        . "4. Jika pesanan selesai, sistem akan membuat tagihan pelunasan sesuai final harga.\n"
        . "Jika status belum berubah beberapa saat setelah membayar, muat ulang halaman Detail Order.";
      return $this->withOrderContext($reply, $lastOrder);
    }

    if ($mentions(['fitur', 'fitur yang tersedia', 'apa saja fitur', 'pelanggan', 'pengguna'])) {
      return "Fitur utama TukangDekat untuk pelanggan meliputi:\n"
        . "- Registrasi dan login akun.\n"
        . "- Cari kategori layanan dan pilih tukang.\n"
        . "- Buat pesanan dengan jadwal, alamat, dan catatan pekerjaan.\n"
        . "- Bayar menggunakan QRIS untuk DP dan pelunasan.\n"
        . "- Pantau status pesanan dan riwayat pesanan.\n"
        . "- Batalkan pesanan jika belum dikerjakan.\n"
        . "- Beri rating dan review setelah pekerjaan selesai.";
    }

    if ($mentions(['pesan', 'order', 'memesan', 'booking', 'cara'])) {
      return "Cara memesan jasa di TukangDekat:\n"
        . "1. Pilih kategori jasa yang kamu butuhkan.\n"
        . "2. Pilih penyedia (tukang) yang tersedia di sekitarmu.\n"
        . "3. Tentukan jadwal dan tambahkan catatan kebutuhanmu.\n"
        . "4. Konfirmasi pesanan, lalu bayar DP setelah penyedia menerima pesananmu.";
    }

    if ($mentions(['halo', 'hai', 'hello', 'assalam', 'pagi', 'siang', 'sore', 'malam', 'terima kasih', 'makasih'])) {
      return "Halo! Saya asisten TukangDekat. Saya bisa membantu soal status pesanan, informasi pembayaran, cara memesan jasa, pembatalan pesanan, dan fitur aplikasi. Ada yang bisa saya bantu?";
    }

    return "Maaf, saya belum menemukan informasi tersebut pada dokumentasi aplikasi.";
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
