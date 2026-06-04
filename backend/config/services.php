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
        'url' => env('N8N_URL', 'http://localhost:5678'),
        'webhook_key' => env('N8N_WEBHOOK_KEY'),
        'workflows' => [
            'order_created_WA' => env('N8N_WORKFLOW_ORDER_CREATED_WA'),
            'order_accepted_WA' => env('N8N_WORKFLOW_ORDER_ACCEPTED_WA'),
            'order_rejected_WA' => env('N8N_WORKFLOW_ORDER_REJECTED_WA'),
            'dp_paid_WA' => env('N8N_WORKFLOW_DP_PAID_WA'),
            'order_completed_WA' => env('N8N_WORKFLOW_ORDER_COMPLETED_WA'),
            'final_paid_WA' => env('N8N_WORKFLOW_FINAL_PAID_WA'),
            'payment_failed_WA' => env('N8N_WORKFLOW_PAYMENT_FAILED_WA'),
            'payout_completed_WA' => env('N8N_WORKFLOW_PAYOUT_COMPLETED_WA'),
        ],
        'wa_provider' => env('N8N_WA_PROVIDER', 'fonnte'),
        'wa_api_key' => env('N8N_WA_API_KEY'),
        'email_from' => env('N8N_EMAIL_FROM', 'noreply@tukangdekat.id'),
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
    ],

];
