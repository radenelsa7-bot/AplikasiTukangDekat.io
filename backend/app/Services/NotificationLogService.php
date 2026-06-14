<?php

namespace App\Services;

use App\Models\NotificationLog;

class NotificationLogService
{
    public function log(string $eventName, string $channel, array $payload, string $status): void
    {
        NotificationLog::create([
            'event_name' => $eventName,
            'channel' => $channel,
            'payload_json' => json_encode($payload),
            'status' => $status,
            'sent_at' => now(),
        ]);
    }
}
