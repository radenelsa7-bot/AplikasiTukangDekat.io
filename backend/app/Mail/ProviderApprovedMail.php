<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class ProviderApprovedMail extends Mailable
{
    use Queueable, SerializesModels;

    public User $provider;

    /**
     * Create a new message instance.
     */
    public function __construct(User $provider)
    {
        $this->provider = $provider;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Verifikasi Berhasil! Selamat Datang di TukangDekat',
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.provider-approved',
            with: [
                'providerName' => $this->provider->name,
                'businessName' => $this->provider->providerProfile?->business_name ?? $this->provider->name,
                'appUrl' => config('app.url', 'http://localhost'),
            ],
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }
}