<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\MetricsCollectorService;

class MetricsController extends Controller
{
    public function show(MetricsCollectorService $metricsCollector)
    {
        $metrics = $metricsCollector->collect();
        $text = $metricsCollector->toPrometheusText($metrics);

        return response($text, 200)
            ->header('Content-Type', 'text/plain; charset=UTF-8');
    }
}
