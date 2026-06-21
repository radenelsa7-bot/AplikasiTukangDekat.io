<?php

return [
    'order_context_count' => env('CHATBOT_ORDER_CONTEXT_COUNT', 1),

    'gemini_retry' => [
        'times' => env('CHATBOT_GEMINI_RETRY_TIMES', 3),
        'base_sleep_ms' => env('CHATBOT_GEMINI_BASE_SLEEP_MS', 200),
    ],

    'max_history' => env('CHATBOT_MAX_HISTORY', 100),

    'rate_limit' => [
        'limit' => env('CHATBOT_RATE_LIMIT_LIMIT', 10),
        'period' => env('CHATBOT_RATE_LIMIT_PERIOD_SECONDS', 60),
    ],
];