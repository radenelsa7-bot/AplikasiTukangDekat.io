<?php

namespace App\Services\Payout;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use App\Models\PayoutProviderResponse;
use App\Notifications\PayoutFailed;

/**
 * Simple Xendit payout adapter scaffold.
 *
 * Notes:
 * - Requires XENDIT_API_KEY in environment to be useful.
 * - The exact endpoint/payload may need adjustment to match the provider API.
 */
class XenditPayoutGateway implements PayoutGatewayInterface
{
    protected string $apiKey;
    protected string $baseUrl;
    protected string $disbursementPath;

    public function __construct(string $apiKey, string $baseUrl = 'https://api.xendit.com')
    {
        $this->apiKey = $apiKey;
        $this->baseUrl = rtrim($baseUrl, '/');
        $this->disbursementPath = env('XENDIT_DISBURSEMENT_PATH', '/disbursements');
    }

    public function send(array $payload): array
    {
        // Quick guard: allow forced mock failure for tests
        if (!empty($payload['force_fail'])) {
            return [
                'success' => false,
                'error' => 'forced-failure',
                'meta' => ['mock' => 1]
            ];
        }
        try {
            $reference = 'payout_' . time() . '_' . rand(1000, 9999);

            $variants = $this->buildVariants($payload, $reference);
            $paths = $this->buildPaths();

            $res = $this->attemptPathsAndVariants($paths, $variants);

            // Persist provider response if available
            if ($res) {
                try {
                    try {
                        @file_put_contents(base_path('storage/gateway_debug_precreate.txt'), json_encode(['pre' => true]));
                        $pathValue = null;
                        if (is_object($res) && method_exists($res, 'effectiveUri')) {
                            try {
                                $pathValue = $res->effectiveUri() ? (string) $res->effectiveUri() : null;
                            } catch (\Throwable $_) {
                                $pathValue = null;
                            }
                        }

                        PayoutProviderResponse::create([
                            'provider' => 'xendit',
                            'transaction_reference' => $res->json()['id'] ?? ($res->json()['reference'] ?? null),
                            'path' => $pathValue,
                            'request_body' => $variants[0] ?? null,
                            'response_body' => $res->json() ?? ['body' => $res->body()],
                            'status_code' => $res->status(),
                        ]);
                        @file_put_contents(base_path('storage/gateway_debug_postcreate.txt'), json_encode(['post' => true]));
                    } catch (\Throwable $e) {
                        @file_put_contents(base_path('storage/gateway_debug_create_err.txt'), $e->getMessage());
                        Log::warning('xendit.persist_response_failed', ['err' => $e->getMessage()]);
                    }
                } catch (\Throwable $e) {
                    Log::warning('xendit.persist_response_failed', ['err' => $e->getMessage()]);
                }
            }

            if ($res && $res->successful()) {
                $body = $res->json();
                return [
                    'success' => true,
                    'transaction_reference' => $body['id'] ?? ($body['reference'] ?? null),
                    'meta' => $body,
                ];
            }

            // If provider returned non-success, trigger alert (email + DB notification)
            if ($res) {
                try {
                    $reference = null;
                    try { $reference = $res->json()['id'] ?? ($res->json()['reference'] ?? null); } catch (\Throwable $_) { $reference = null; }

                    // send mail notification to configured alert email
                    $alertEmail = env('PAYOUT_ALERT_EMAIL');
                    if ($alertEmail) {
                        Notification::route('mail', $alertEmail)->notify(new PayoutFailed('xendit', $reference, $res->status(), $res->json() ?? ['body' => $res->body()]));
                    }

                    // send webhook if configured
                    $webhook = env('PAYOUT_ALERT_WEBHOOK');
                    if ($webhook) {
                        try {
                            Http::post($webhook, [
                                'provider' => 'xendit',
                                'reference' => $reference,
                                'status_code' => $res->status(),
                                'response' => $res->json() ?? ['body' => $res->body()],
                            ]);
                        } catch (\Throwable $_) {
                            // Ignore webhook failures
                        }
                    }
                } catch (\Throwable $e) {
                    Log::warning('xendit.alert_failed', ['err' => $e->getMessage()]);
                }
            }

            return [
                'success' => false,
                'error' => $res ? $res->body() : 'No response from provider',
                'meta' => $res ? ($res->json() ?? null) : null,
            ];
        } catch (\Throwable $e) {
            Log::error('xendit.send_error', ['err' => $e->getMessage()]);
            return [
                'success' => false,
                'error' => $e->getMessage(),
            ];
        }
    }

    protected function buildVariants(array $payload, string $reference): array
    {
        $v2 = [
            'external_id' => $reference,
            'currency' => 'IDR',
            'channel_code' => strtoupper($payload['bank_code'] ?? 'MANDIRI'),
            'channel_properties' => [
                'account_number' => $payload['account_number'] ?? '0000000000',
            ],
            'amount' => (int) round($payload['amount'] ?? 0),
            'description' => $payload['description'] ?? 'Provider payout',
        ];

        $legacy = [
            'external_id' => $reference,
            'bank_code' => strtoupper($payload['bank_code'] ?? 'MANDIRI'),
            'amount' => (int) round($payload['amount'] ?? 0),
        ];

        // Legacy first to support older sandbox endpoints, then V2
        return [$legacy, $v2];
    }

    protected function buildPaths(): array
    {
        $paths = [
            $this->disbursementPath,
            '/disbursements',
            '/v2/disbursements',
            '/disbursement',
        ];
        return array_values(array_unique(array_map(fn($path) => '/' . ltrim($path, '/'), $paths)));
    }

    protected function attemptPathsAndVariants(array $paths, array $variants)
    {
        foreach ($paths as $path) {
            foreach ($variants as $requestBody) {
                $res = $this->postToPath($path, $requestBody);

                if (env('XENDIT_DEBUG', false)) {
                    try {
                        Log::debug('xendit.request', ['path' => $path, 'request' => $requestBody, 'status' => $res->status(), 'body' => $res->body()]);
                    } catch (\Throwable $e) {
                        Log::warning('xendit.debug.log_failed', ['err' => $e->getMessage()]);
                    }
                }

                // If validation error, try a sanitized JSON retry and a form fallback
                $jsonBody = null;
                try {
                    $jsonBody = $res->json();
                } catch (\Throwable $e) {
                    $jsonBody = null;
                }

                if ($jsonBody && (data_get($jsonBody, 'error_code') === 'API_VALIDATION_ERROR' || $res->status() === 422)) {
                    $res = $this->handleValidationErrorRetry($res, $path, $requestBody);
                }

                if ($res->status() !== 404) {
                    return $res;
                }
            }
        }

        return null;
    }

    protected function postToPath(string $path, array $body)
    {
        return Http::withHeaders([
            'Authorization' => 'Basic ' . base64_encode($this->apiKey . ':'),
            'X-IDEMPOTENCY-KEY' => 'idem_' . sha1(($body['external_id'] ?? uniqid('', true)) . $path),
        ])->timeout(15)->post($this->baseUrl . $path, $body);
    }

    protected function handleValidationErrorRetry($res, string $path, array $requestBody)
    {
        $jsonBody = null;
        try {
            $jsonBody = $res->json();
        } catch (\Throwable $e) {
            $jsonBody = null;
        }

        $errors = data_get($jsonBody, 'errors', []);
        $disallowed = [];
        foreach ($errors as $err) {
            if (!empty($err['path']) && is_array($err['path'])) {
                $disallowed[] = $err['path'][0];
            }
        }

        if (empty($disallowed)) {
            return $res;
        }

        $sanitized = $requestBody;
        foreach ($disallowed as $key) {
            if (array_key_exists($key, $sanitized)) {
                unset($sanitized[$key]);
            }
        }

        // Retry JSON
        $res = $this->postToPath($path, $sanitized);
        if (env('XENDIT_DEBUG', false)) {
            Log::debug('xendit.request.sanitized', ['path' => $path, 'request' => $sanitized, 'status' => $res->status(), 'body' => $res->body()]);
        }

        try {
            $jsonBody2 = $res->json();
        } catch (\Throwable $e) {
            $jsonBody2 = null;
        }

        if ($jsonBody2 && data_get($jsonBody2, 'error_code') === 'API_VALIDATION_ERROR') {
            // Form-encoded fallback
            $res = Http::asForm()->withHeaders([
                'Authorization' => 'Basic ' . base64_encode($this->apiKey . ':'),
                'X-IDEMPOTENCY-KEY' => 'idem_' . sha1(($sanitized['external_id'] ?? uniqid('', true)) . $path),
            ])->timeout(15)->post($this->baseUrl . $path, $sanitized);

            if (env('XENDIT_DEBUG', false)) {
                Log::debug('xendit.request.sanitized.form', ['path' => $path, 'request' => $sanitized, 'status' => $res->status(), 'body' => $res->body()]);
            }
        }

        return $res;
    }
}
