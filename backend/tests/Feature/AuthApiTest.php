<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\ServiceCategory;
use App\Models\ProviderProfile;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_customer_creates_user_and_returns_user_id(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Test Customer',
            'email' => 'customer@example.com',
            'phone' => '081234567890',
            'password' => 'Secret123!',
            'password_confirmation' => 'Secret123!',
            'role' => 'CUSTOMER',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'message',
                'data' => [
                    'user' => ['id', 'name', 'email', 'role'],
                ],
            ])
            ->assertJsonPath('message', 'User registered successfully')
            ->assertJsonPath('data.user.email', 'customer@example.com')
            ->assertJsonPath('data.user.role', 'CUSTOMER');

        $this->assertDatabaseHas('users', [
            'email' => 'customer@example.com',
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);
    }

    public function test_register_provider_creates_provider_profile(): void
    {
        // RegisterRequest requires category_id + business_name when role=PROVIDER
        $category = ServiceCategory::factory()->create();

        $response = $this->postJson('/api/auth/register', [
            'name' => 'Test Provider',
            'email' => 'provider@example.com',
            'phone' => '081234567891',
            'password' => 'Secret123!',
            'password_confirmation' => 'Secret123!',
            'role' => 'PROVIDER',
            'category_id' => $category->id,
            'business_name' => 'PT Test Provider',
            'service_name' => 'Layanan Test',
            'base_price' => 10000,
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.user.role', 'PROVIDER');

        $this->assertDatabaseHas('users', [
            'email' => 'provider@example.com',
            'role' => 'PROVIDER',
        ]);

        $userId = $response->json('data.user.id');
        $this->assertDatabaseHas('provider_profiles', ['user_id' => $userId]);

        $this->assertDatabaseHas('provider_profiles', [
            'user_id' => $userId,
            'business_name' => 'PT Test Provider',
        ]);
    }

    public function test_login_returns_token_with_valid_credentials(): void
    {
        $user = User::factory()->create([
            'email' => 'login@example.com',
            'password' => 'password',
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'login@example.com',
            'password' => 'password',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'message',
                'data' => [
                    'token',
                    'token_type',
                    'user' => ['id', 'name', 'email', 'role'],
                ],
            ])
            ->assertJsonPath('data.user.email', 'login@example.com');
    }

    public function test_login_rejects_invalid_credentials(): void
    {
        User::factory()->create([
            'email' => 'fail@example.com',
            'password' => 'password',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'fail@example.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401)
            ->assertJson(['message' => 'The provided credentials are incorrect.']);
    }

    public function test_logout_revokes_current_token(): void
    {
        $user = User::factory()->create([
            'email' => 'logout@example.com',
            'password' => 'password',
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/auth/logout');

        $response->assertStatus(200)
            ->assertJsonPath('message', 'Logged out successfully');
    }
}
