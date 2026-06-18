<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'n8n' => [
        'webhook_url' => env('N8N_WEBHOOK_URL'),
        'secret' => env('N8N_WEBHOOK_SECRET'),
        'event_secret' => env('N8N_EVENT_SECRET'),
    ],

    'payments' => [
        'driver' => env('PAYMENT_GATEWAY_DRIVER', 'simulation'),
        'charge_url' => env('PAYMENT_GATEWAY_CHARGE_URL'),
        'api_token' => env('PAYMENT_GATEWAY_API_TOKEN'),
        'webhook_secret' => env('PAYMENT_GATEWAY_WEBHOOK_SECRET'),
        'webhook_signature_header' => env('PAYMENT_GATEWAY_SIGNATURE_HEADER', 'X-Payment-Signature'),
        'platform_commission_percent' => env('PLATFORM_COMMISSION_PERCENT', 10),
        'dp_refund_percent' => env('DP_REFUND_PERCENT', 100),
        'midtrans_server_key' => env('MIDTRANS_SERVER_KEY'),
        'midtrans_client_key' => env('MIDTRANS_CLIENT_KEY'),
        'midtrans_is_production' => env('MIDTRANS_IS_PRODUCTION', false),
        'xendit_secret_key' => env('XENDIT_SECRET_KEY', env('XENDIT_API_KEY')),
        'xendit_charge_url' => env('XENDIT_CHARGE_URL', rtrim(env('XENDIT_BASE_URL', ''), '/')),
    ],

    'payouts' => [
        'alert_webhook' => env('PAYOUT_ALERT_WEBHOOK'),
        'alert_email' => env('PAYOUT_ALERT_EMAIL'),
    ],
    'gemini' => [
        'endpoint' => env('GEMINI_API_ENDPOINT', 'https://generativeai.googleapis.com/v1'),
        'model' => env('GEMINI_MODEL', 'gemini-1.0'),
        'key' => env('GEMINI_API_KEY'),
    ],

];
