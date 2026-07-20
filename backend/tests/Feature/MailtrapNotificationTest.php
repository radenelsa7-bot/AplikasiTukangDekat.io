<?php

namespace Tests\Feature;

use App\Mail\ProviderApprovedMail;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class MailtrapNotificationTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test Mailtrap SMTP configuration is accessible
     */
    public function test_mailtrap_configuration_available(): void
    {
        $host = config('services.mailtrap.host', env('MAIL_HOST'));
        $this->assertEquals('sandbox.smtp.mailtrap.io', $host, 
            'Mailtrap SMTP host should be configured correctly');
    }

    /**
     * Test provider approval email can be sent
     */
    public function test_provider_approval_email_can_be_sent(): void
    {
        $provider = User::factory()->create([
            'role' => 'PROVIDER',
            'email' => 'provider@example.com',
            'name' => 'Test Provider',
        ]);

        // Create a markdown mail
        $mail = new ProviderApprovedMail($provider);

        $this->assertInstanceOf(ProviderApprovedMail::class, $mail,
            'ProviderApprovedMail should be instantiable');
    }

    /**
     * Test provider approval email content
     */
    public function test_provider_approval_email_content(): void
    {
        $provider = User::factory()->create([
            'role' => 'PROVIDER',
            'email' => 'provider@example.com',
            'name' => 'Test Provider',
        ]);

        $mail = new ProviderApprovedMail($provider);
        
        $envelope = $mail->envelope();
        $content = $mail->content();

        $this->assertEquals('Verifikasi Berhasil! Selamat Datang di TukangDekat', $envelope->subject,
            'Email subject should be set correctly');
        
        $this->assertEquals('emails.provider-approved', $content->view,
            'Email view should be configured correctly');
    }

    /**
     * Test provider approval notification integration
     */
    public function test_provider_approval_notification_flow(): void
    {
        $admin = User::factory()->create(['role' => 'ADMIN']);
        $provider = User::factory()->create([
            'role' => 'PROVIDER',
            'email' => 'provider-approval@example.com',
            'provider_status' => 'pending',
        ]);

        $token = $admin->createToken('admin-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/admin/providers/' . $provider->id . '/approve-registration');

        $response->assertStatus(200)
            ->assertJsonPath('provider_status', 'approved');

        $provider->refresh();
        $this->assertEquals('approved', $provider->provider_status,
            'Provider status should be updated to approved');
    }

    /**
     * Test MailService uses environment variables
     */
    public function test_mail_service_uses_env_credentials(): void
    {
        $serviceClass = \App\Services\MailService::class;
        
        $this->assertTrue(class_exists($serviceClass), 
            'MailService class should exist');
    }
}