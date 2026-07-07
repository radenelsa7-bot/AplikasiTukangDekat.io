<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or cross-domain requests. These settings are used by the CORS middleware
    | and are merged with Laravel's default CORS configuration when the file
    | exists in the application config directory.
    |
    */

    'paths' => [
        'api/*',
        'storage/*',
        'sanctum/csrf-cookie',
    ],

    'allowed_methods' => ['*'],

    'allowed_origins' => explode(',', env('CORS_ALLOWED_ORIGINS', 'http://localhost:8000,http://localhost:3000,http://localhost:5173,http://127.0.0.1:8000,http://127.0.0.1:3000,http://127.0.0.1:5173')),

    'allowed_origins_patterns' => [
        '/^http:\/\/localhost(:\d+)?$/',
        '/^http:\/\/127\.0\.0\.1(:\d+)?$/',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,
];
