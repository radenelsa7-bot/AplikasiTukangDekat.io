<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Cache;
use Illuminate\Http\Request;

class CollectMetrics
{
    public function handle(Request $request, Closure $next)
    {
        $start = microtime(true);
        $response = $next($request);
        $duration = microtime(true) - $start;

        // Simple in-memory metrics stored in cache (array driver supports tests)
        // requests_total
        $total = (int) Cache::get('metrics.requests_total', 0) + 1;
        Cache::put('metrics.requests_total', $total);

        // request_duration_seconds_sum and count for histogram
        $sum = (float) Cache::get('metrics.request_duration_seconds_sum', 0) + $duration;
        $count = (int) Cache::get('metrics.request_duration_seconds_count', 0) + 1;
        Cache::put('metrics.request_duration_seconds_sum', $sum);
        Cache::put('metrics.request_duration_seconds_count', $count);

        // last request time
        Cache::put('metrics.last_request_at', now()->toDateTimeString());

        return $response;
    }
}
