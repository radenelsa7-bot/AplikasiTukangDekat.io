<?php
require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();
$db = app('db');
$payments = $db->table('payments')->orderBy('id', 'desc')->limit(10)->get();
$notifications = $db->table('notification_logs')->orderBy('id', 'desc')->limit(10)->get();
echo json_encode(['payments' => $payments, 'notification_logs' => $notifications], JSON_PRETTY_PRINT);
