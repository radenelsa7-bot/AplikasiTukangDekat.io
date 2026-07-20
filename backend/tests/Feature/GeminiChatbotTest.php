<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GeminiChatbotTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test Gemini API configuration is available
     */
    public function test_gemini_api_configuration(): void
    {
        $endpoint = config('services.gemini.endpoint');
        $model = config('services.gemini.model');
        $key = config('services.gemini.key');

        $this->assertNotNull($endpoint, 'Gemini API endpoint should be configured');
        $this->assertNotNull($model, 'Gemini API model should be configured');
        $this->assertNotNull($key, 'Gemini API key should be configured');
    }

    /**
     * Test chatbot endpoint returns response
     */
    public function test_chatbot_endpoint_returns_response(): void
    {
        $user = User::factory()->create([
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/chatbot/send', [
                'message' => 'Halo, ada yang bisa saya tanya?'
            ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'message',
                'data' => ['reply'],
            ]);
    }

    /**
     * Test chatbot fallback works without API key
     */
    public function test_chatbot_fallback_without_api_key(): void
    {
        // Set Gemini key to empty to test fallback
        config(['services.gemini.key' => null]);
        
        $user = User::factory()->create([
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/chatbot/send', [
                'message' => 'Halo'
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.reply', 'Halo! Saya asisten TukangDekat. Saya bisa membantu soal status pesanan, informasi pembayaran, cara memesan jasa, pembatalan pesanan, dan fitur aplikasi. Ada yang bisa saya bantu?');
    }

    /**
     * Test chatbot handles order status queries
     */
    public function test_chatbot_handles_order_status(): void
    {
        config(['services.gemini.key' => null]); // Use fallback
        
        $customer = User::factory()->create([
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $provider = User::factory()->create(['role' => 'PROVIDER']);

        $order = Order::create([
            'order_code' => 'ORD-20260720-001',
            'customer_id' => $customer->id,
            'provider_id' => $provider->id,
            'schedule_at' => now()->addDay(),
            'address' => 'Test Address',
            'estimated_price' => 100000,
            'status' => 'CREATED',
        ]);

        $token = $customer->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/chatbot/send', [
                'message' => 'Status pesananku?'
            ]);

        $response->assertStatus(200);
        $reply = $response->json('data.reply');
        
        $this->assertStringContainsString('ORD-20260720-001', $reply,
            'Chatbot should mention order code in reply');
    }

    /**
     * Test chatbot handles payment queries
     */
    public function test_chatbot_handles_payment_query(): void
    {
        config(['services.gemini.key' => null]); // Use fallback
        
        $user = User::factory()->create([
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/chatbot/send', [
                'message' => 'Bagaimana cara bayar?'
            ]);

        $response->assertStatus(200);
        $reply = $response->json('data.reply');
        
        $this->assertStringContainsString('QRIS', $reply,
            'Chatbot should mention QRIS in reply');
    }

    /**
     * Test chatbot returns empty array for actions when needed
     */
    public function test_chatbot_actions_format(): void
    {
        $user = User::factory()->create([
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/chatbot/send', [
                'message' => 'Fitur aplikasi apa saja?'
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.actions', []);
    }

    /**
     * Test chatbot validation requires message
     */
    public function test_chatbot_requires_message(): void
    {
        $user = User::factory()->create([
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/chatbot/send', []);

        $response->assertStatus(422);
    }
}