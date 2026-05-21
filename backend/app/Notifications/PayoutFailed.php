<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\MailMessage;

class PayoutFailed extends Notification
{
    use Queueable;

    protected $provider;
    protected $reference;
    protected $statusCode;
    protected $response;

    public function __construct(string $provider, ?string $reference, ?int $statusCode, $response)
    {
        $this->provider = $provider;
        $this->reference = $reference;
        $this->statusCode = $statusCode;
        $this->response = $response;
    }

    public function via($notifiable)
    {
        return ['mail', 'database'];
    }

    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject("[Payout] Gagal: {$this->provider}")
            ->line('Payout gagal dikirim ke provider.')
            ->line('Provider: ' . $this->provider)
            ->line('Reference: ' . ($this->reference ?? '-'))
            ->line('Status code: ' . ($this->statusCode ?? '-'))
            ->line('Response: ' . json_encode($this->response))
            ->line('Periksa log atau dashboard untuk informasi lebih lanjut.');
    }

    public function toArray($notifiable)
    {
        return [
            'provider' => $this->provider,
            'reference' => $this->reference,
            'status_code' => $this->statusCode,
            'response' => $this->response,
        ];
    }
}
