<?php

namespace Tests\Unit;

use App\Services\GeminiService;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GeminiServiceTest extends TestCase
{
    public function test_send_returns_assistant_message_on_success()
    {
        $fakeResponse = [
            'choices' => [
                [
                    'message' => ['content' => 'Halo, ini balasan dari Gemini.']
                ]
            ]
        ];

        Http::fake([
            '*' => Http::response($fakeResponse, 200)
        ]);

        $service = new GeminiService();

        // Ensure configuration exists in test environment (set via config helper)
        config(['services.gemini.endpoint' => 'https://example.test/generate']);
        config(['services.gemini.api_key' => 'test-key']);
        config(['services.gemini.model' => 'gemini-1.0']);

        $result = $service->send([
            ['role' => 'system', 'content' => 'system'],
            ['role' => 'user', 'content' => 'hello'],
        ], 128);

        $this->assertIsArray($result);
        $this->assertFalse($result['error']);
        $this->assertEquals('Halo, ini balasan dari Gemini.', $result['assistant']);
    }
}
