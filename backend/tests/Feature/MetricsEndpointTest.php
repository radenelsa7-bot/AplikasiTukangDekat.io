<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Services\MetricsCollectorService;

class MetricsEndpointTest extends TestCase
{
    public function test_metrics_endpoint_returns_plain_text_prometheus_metrics()
    {
        $stub = new class extends MetricsCollectorService {
            public function __construct()
            {
                // No monitoring service dependency required for this stub.
            }

            public function collect(?int $windowMinutes = null): array
            {
                return [
                    'payout_attempts_total' => 2,
                    'failed_payout_attempts_total' => 1,
                ];
            }

            public function toPrometheusText(array $metrics): string
            {
                return "tukangdekat_payout_attempts_total 2\ntukangdekat_failed_payout_attempts_total 1\n";
            }
        };

        $this->instance(MetricsCollectorService::class, $stub);

        $response = $this->get('/api/metrics');

        $response->assertStatus(200);
        $response->assertHeader('Content-Type', 'text/plain; charset=UTF-8');
        $response->assertSee('tukangdekat_payout_attempts_total 2');
        $response->assertSee('tukangdekat_failed_payout_attempts_total 1');
    }
}

