<?php
require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();
$db = app('db');
$notifications = $db->table('notification_logs')->orderBy('id', 'desc')->limit(5)->get();
echo json_encode($notifications, JSON_PRETTY_PRINT);
