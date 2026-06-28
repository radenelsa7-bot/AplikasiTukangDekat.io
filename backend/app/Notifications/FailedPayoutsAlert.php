<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\MailMessage;

class FailedPayoutsAlert extends Notification
{
    use Queueable;

    protected int $failedCount;
    protected int $windowMinutes;
    protected int $threshold;
    protected int $criticalThreshold;
    protected string $severity;
    protected string $timestamp;

    public function __construct(int $failedCount, int $windowMinutes, int $threshold, int $criticalThreshold, string $severity, string $timestamp)
    {
        $this->failedCount = $failedCount;
        $this->windowMinutes = $windowMinutes;
        $this->threshold = $threshold;
        $this->criticalThreshold = $criticalThreshold;
        $this->severity = $severity;
        $this->timestamp = $timestamp;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject(sprintf('[Alert][%s] Failed provider payout attempts', strtoupper($this->severity)))
            ->line('A payout alert has been triggered for failed provider payout attempts.')
            ->line('Failed attempts: ' . $this->failedCount)
            ->line('Window (minutes): ' . $this->windowMinutes)
            ->line('Alert threshold: ' . $this->threshold)
            ->line('Critical threshold: ' . $this->criticalThreshold)
            ->line('Severity: ' . ucfirst($this->severity))
            ->line('Timestamp: ' . $this->timestamp)
            ->line('Please review the payout monitoring dashboard and investigate the failure trend.');
    }
}
