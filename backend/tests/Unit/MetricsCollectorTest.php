<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Services\MetricsCollectorService;

class MetricsCollectorTest extends TestCase
{
    public function test_to_prometheus_text_formats_metrics_correctly()
    {
        $service = app(MetricsCollectorService::class);

        $metrics = [
            'payout_attempts_total' => 4,
            'recent_failed_payout_attempts_total' => 1,
            'alert_triggered' => true,
        ];

        $text = $service->toPrometheusText($metrics);

        $this->assertStringContainsString('tukangdekat_payout_attempts_total 4', $text);
        $this->assertStringContainsString('tukangdekat_recent_failed_payout_attempts_total 1', $text);
        $this->assertStringContainsString('tukangdekat_alert_triggered 1', $text);
    }
}
