<?php

namespace App\Services;

use App\Models\NotificationLog;

class RealtimeNotificationService
{
    /**
     * Fallback real-time: persist event as NotificationLog.
     *
     * Intended integration point for future WebSocket broadcasting.
     */
    public function broadcast(string $eventName, string $recipientChannel, array $payload): NotificationLog
    {
        // Table constraint only allows enum values: WA or EMAIL.
        // For role-based delivery, we keep the destination detail inside payload_json.
        $channelEnum = strtoupper(trim($recipientChannel));
        if (!in_array($channelEnum, ['WA', 'EMAIL'], true)) {
            $channelEnum = 'WA';
        }

        return NotificationLog::create([
            'event_name' => $eventName,
            'channel' => $channelEnum,
            'payload_json' => json_encode($payload),
            'status' => 'SENT',
            'sent_at' => now(),
        ]);
    }

    public function recipientChannelFor(string $role, int|string $userId): string
    {
        return strtolower($role) . ":" . (string) $userId;
    }

    /**
     * Helper for building payload destination metadata.
     */
    public function destinationPayload(string $recipientChannel, array $payload): array
    {
        return array_merge($payload, ['recipient_channel' => $recipientChannel]);
    }

}

