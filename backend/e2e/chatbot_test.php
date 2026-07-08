<?php

$token = trim(file_get_contents(__DIR__ . '/.env'));
if (!preg_match('/TEST_TOKEN=(.+)/', $token, $matches)) {
    echo "TOKEN not found in e2e/.env\n";
    exit(1);
}
$token = trim($matches[1]);

$baseUrl = 'http://127.0.0.1:8000/api';
$scenarios = [
    'cara_pesan' => 'Bagaimana cara memesan tukang di aplikasi?',
    'alur_pembayaran' => 'Jelaskan alur pembayaran di aplikasi TukangDekat.',
    'pembatalan' => 'Bagaimana kalau saya ingin membatalkan pesanan?',
    'fitur_ada' => 'Apa saja fitur yang tersedia untuk pelanggan di aplikasi ini?',
    'tidak_ada' => 'Apa fungsi menu pengaturan pesawat terbang?',
];

function callChatbot($baseUrl, $token, $message)
{
    $url = $baseUrl . '/chatbot/send';
    $payload = json_encode(['message' => $message]);

    $options = [
        'http' => [
            'method' => 'POST',
            'header' => "Content-Type: application/json\r\n" .
                        "Authorization: Bearer $token\r\n",
            'content' => $payload,
            'ignore_errors' => true,
            'timeout' => 30,
        ],
    ];
    $context = stream_context_create($options);
    $result = @file_get_contents($url, false, $context);
    $status = null;
    if (isset($http_response_header[0])) {
        preg_match('#HTTP/\d+\.\d+\s+(\d+)#', $http_response_header[0], $m);
        $status = $m[1] ?? null;
    }

    return [$status, $result ?: ''];
}

foreach ($scenarios as $key => $message) {
    echo "=== Scenario: $key ===\n";
    echo "Input: $message\n";
    list($status, $body) = callChatbot($baseUrl, $token, $message);
    echo "Status: " . ($status ?? 'unknown') . "\n";
    echo "Response: $body\n\n";
}
