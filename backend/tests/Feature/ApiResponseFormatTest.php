<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ApiResponseFormatTest extends TestCase
{
    use RefreshDatabase;

    public function test_auth_endpoints_return_consistent_json_structure(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Test User',
            'email' => 'format-test@example.com',
            'phone' => '081234567890',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
            'role' => 'CUSTOMER',
        ]);

        $this->assertSame(201, $response->status());
        $this->assertTrue($response->json('message') !== null);
        $this->assertTrue($response->json('data') !== null);
    }

    public function test_error_response_has_consistent_structure(): void
    {
        $user = User::factory()->create([
            'email' => 'test-error@example.com',
            'role' => 'CUSTOMER',
        ]);

        $token = $user->createToken('error-test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/admin/providers/pending');

        $this->assertSame(403, $response->status());
        $this->assertTrue($response->json('message') !== null);
    }

    public function test_success_response_includes_data_and_message(): void
    {
        $user = User::factory()->create([
            'email' => 'test-success@example.com',
            'password' => 'password',
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $token = $user->createToken('success-test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/orders/my-orders');

        $this->assertSame(200, $response->status());
        $this->assertTrue($response->json('message') !== null);
        $this->assertTrue(is_array($response->json('data')));
    }
}
