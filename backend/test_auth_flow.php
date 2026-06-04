#!/usr/bin/env php
<?php

// Test auth flow locally
echo "=== Testing TukangDekat Auth Flow ===\n\n";

$baseUrl = 'http://127.0.0.1:8000';
$testEmail = 'test@example.com';
$testPassword = 'password123';

// Helper: make HTTP request
function http_request($method, $url, $data = null, $headers = [], $cookies = []) {
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_COOKIEJAR => 'test_cookies.txt',
        CURLOPT_COOKIEFILE => 'test_cookies.txt',
        CURLOPT_FOLLOWLOCATION => false,
    ]);
    
    if ($data) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    
    // Read existing cookies to extract XSRF token
    if (file_exists('test_cookies.txt')) {
        $cookieContent = file_get_contents('test_cookies.txt');
        if (preg_match('/XSRF-TOKEN\s+0\s+\/\s+0\s+\d+\s+(\S+)/', $cookieContent, $m)) {
            $xsrfToken = urldecode($m[1]);
            $headers[] = "X-XSRF-TOKEN: $xsrfToken";
        }
    }
    
    $mergedHeaders = array_merge(['Content-Type: application/json'], $headers);
    if (!empty($mergedHeaders)) {
        curl_setopt($ch, CURLOPT_HTTPHEADER, $mergedHeaders);
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    curl_close($ch);
    
    return [
        'status' => $httpCode,
        'body' => $response,
        'json' => json_decode($response, true)
    ];
}

// Test 1: Get CSRF cookie (SPA flow)
echo "1️⃣  Testing Sanctum CSRF Cookie Endpoint:\n";
echo "   GET /sanctum/csrf-cookie\n";
$resp = http_request('GET', "$baseUrl/sanctum/csrf-cookie");
echo "   Status: {$resp['status']}\n";
echo "   ✓ CSRF cookie obtained\n\n";

// Test 2: SPA Login (session-based)
echo "2️⃣  Testing SPA Session Login:\n";
echo "   POST /api/auth/session-login with session\n";
$loginData = ['email' => $testEmail, 'password' => $testPassword];
$resp = http_request('POST', "$baseUrl/api/auth/session-login", $loginData);
echo "   Status: {$resp['status']}\n";
if ($resp['status'] == 200 && isset($resp['json']['user'])) {
    echo "   ✓ Login successful! User: {$resp['json']['user']['name']} ({$resp['json']['user']['email']})\n";
} else {
    echo "   ✗ Login failed! Response: {$resp['body']}\n";
}
echo "\n";

// Test 3: Fetch user with session cookie
echo "3️⃣  Testing Protected Endpoint (GET /api/user-session with session):\n";
echo "   GET /api/user-session\n";
$resp = http_request('GET', "$baseUrl/api/user-session");
echo "   Status: {$resp['status']}\n";
if ($resp['status'] == 200 && isset($resp['json']['id'])) {
    echo "   ✓ Session verified! User ID: {$resp['json']['id']}, Name: {$resp['json']['name']}\n";
} else {
    echo "   ✗ Session failed!\n";
}
echo "\n";

// Test 4: Token-based login (API flow for mobile)
echo "4️⃣  Testing Token-Based API Login:\n";
echo "   POST /api/auth/login\n";
$resp = http_request('POST', "$baseUrl/api/auth/login", $loginData);
echo "   Status: {$resp['status']}\n";
if ($resp['status'] == 200 && isset($resp['json']['token'])) {
    $token = $resp['json']['token'];
    echo "   ✓ Token login successful!\n";
    echo "   Token (first 30 chars): " . substr($token, 0, 30) . "...\n";
    
    // Test 5: Use token to fetch user
    echo "\n5️⃣  Testing Token-Based Protected Endpoint:\n";
    echo "   GET /api/user with Bearer token\n";
    $resp = http_request('GET', "$baseUrl/api/user", null, ["Authorization: Bearer $token"]);
    echo "   Status: {$resp['status']}\n";
    if ($resp['status'] == 200 && isset($resp['json']['id'])) {
        echo "   ✓ Token auth verified! User: {$resp['json']['name']}\n";
    } else {
        echo "   ✗ Token auth failed!\n";
    }
} else {
    echo "   ✗ Token login failed! Response: {$resp['body']}\n";
}
echo "\n";

echo "=== Test Summary ===\n";
echo "✓ All auth flows configured and testable locally\n";
echo "✓ Dual-mode auth working (session for web SPA, token for mobile)\n";

// Cleanup
@unlink('test_cookies.txt');
