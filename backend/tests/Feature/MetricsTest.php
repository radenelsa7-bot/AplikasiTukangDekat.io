<?php

namespace Tests\Feature;

use Tests\TestCase;

class MetricsTest extends TestCase
{
    public function test_health_endpoint_records_metrics_and_metrics_endpoint_exposes_them()
    {
        // Ensure fresh cache
        cache()->forget('metrics.requests_total');
        cache()->forget('metrics.request_duration_seconds_sum');
        cache()->forget('metrics.request_duration_seconds_count');

        $this->get('/health')->assertStatus(200)->assertSee('ok');

        $resp = $this->get('/metrics')->assertStatus(200);
        $content = $resp->getContent();

        $this->assertStringContainsString('requests_total', $content);
        $this->assertStringContainsString('request_duration_seconds_sum', $content);
        $this->assertStringContainsString('request_duration_seconds_count', $content);
    }
}
