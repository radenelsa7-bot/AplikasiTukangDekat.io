<?php

namespace Tests\Feature;

use App\Models\ChatMessage;
use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ChatbotControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_chatbot_send_requires_authentication(): void
    {
        $response = $this->postJson('/api/chatbot/send', [
            'message' => 'Halo',
        ]);

        $response->assertStatus(401);
    }

    public function test_authenticated_user_can_send_message_and_chat_history_is_persisted(): void
    {
        Config::set('services.gemini.endpoint', 'https://api.test/gemini');
        Config::set('services.gemini.api_key', 'test-key');
        Config::set('services.gemini.model', 'gemini-1.0');

        Http::fake([
            'https://api.test/gemini' => Http::response([
                'choices' => [
                    [
                        'message' => ['content' => 'Halo, kami akan membantu.'],
                    ],
                ],
            ], 200),
        ]);

        $user = User::factory()->create([
            'email' => 'customer@example.com',
            'password' => 'password',
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $order = Order::factory()->create([
            'customer_id' => $user->id,
            'status' => 'CREATED',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/chatbot/send', [
                'message' => 'Apa status pesanan saya?',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Chatbot response received',
                'data' => [
                    'user_message' => 'Apa status pesanan saya?',
                    'assistant_message' => 'Halo, kami akan membantu.',
                ],
            ]);

        $this->assertDatabaseHas('chat_messages', [
            'user_id' => $user->id,
            'role' => 'user',
            'message' => 'Apa status pesanan saya?',
        ]);

        $this->assertDatabaseHas('chat_messages', [
            'user_id' => $user->id,
            'role' => 'assistant',
            'message' => 'Halo, kami akan membantu.',
        ]);

        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'customer_id' => $user->id,
        ]);
    }

    public function test_throttled_chatbot_send_returns_rate_limit_headers(): void
    {
        Config::set('cache.default', 'array');
        Config::set('services.gemini.endpoint', 'https://api.test/gemini');
        Config::set('services.gemini.api_key', 'test-key');
        Config::set('services.gemini.model', 'gemini-1.0');

        Http::fake([
            'https://api.test/gemini' => Http::response([
                'choices' => [
                    [
                        'message' => ['content' => 'Halo, kami akan membantu.'],
                    ],
                ],
            ], 200),
        ]);

        $user = User::factory()->create([
            'email' => 'customer@example.com',
            'password' => 'password',
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        Order::factory()->create([
            'customer_id' => $user->id,
            'status' => 'CREATED',
        ]);

        for ($i = 0; $i < 10; $i++) {
            $response = $this->actingAs($user, 'sanctum')
                ->postJson('/api/chatbot/send', ['message' => 'Apa status pesanan saya?']);

            $response->assertStatus(200);
        }

        $rateLimitResponse = $this->actingAs($user, 'sanctum')
            ->postJson('/api/chatbot/send', ['message' => 'Apa status pesanan saya?']);

        $rateLimitResponse->assertStatus(429)
            ->assertHeader('X-RateLimit-Limit', '10')
            ->assertHeader('X-RateLimit-Remaining', '0')
            ->assertHeader('Retry-After')
            ->assertHeader('X-RateLimit-Reset')
            ->assertJson([
                'message' => 'Too Many Requests',
                'errors' => [
                    'code' => 'TOO_MANY_REQUESTS',
                ],
            ]);
    }
}
