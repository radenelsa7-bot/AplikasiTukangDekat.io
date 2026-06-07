<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\ServiceCategory;
use App\Models\ProviderProfile;
use App\Models\ProviderService;

class SmokeTestFeature extends TestCase
{
    use RefreshDatabase;

    /**
     * Setup test data before each test
     */
    public function setUp(): void
    {
        parent::setUp();
        
        // Create test categories
        ServiceCategory::create([
            'name' => 'Cleaning',
            'description' => 'Cleaning services',
            'icon' => 'cleaning.svg',
        ]);

        // Create test provider
        $provider = User::create([
            'name' => 'Test Provider',
            'email' => 'provider@test.com',
            'phone' => '081234567890',
            'password' => bcrypt('password'),
            'role' => 'PROVIDER',
            'is_verified' => true,
        ]);

        // Create provider profile
        ProviderProfile::create([
            'user_id' => $provider->id,
            'area' => 'Jakarta',
            'experience_years' => 5,
            'avg_rating' => 4.5,
            'service_count' => 1,
            'is_verified' => true,
        ]);

        // Create provider service
        ProviderService::create([
            'provider_id' => $provider->id,
            'category_id' => ServiceCategory::first()->id,
            'name' => 'Cleaning Service',
            'description' => 'Professional cleaning',
            'base_price' => 100000,
        ]);

        // Create test customer
        User::create([
            'name' => 'Test Customer',
            'email' => 'customer@test.com',
            'phone' => '082345678901',
            'password' => bcrypt('password'),
            'role' => 'CUSTOMER',
        ]);
    }

    /**
     * Test 1: Smoke Test - API Health Check (Categories endpoint)
     * @test
     */
    public function test_health_endpoint_categories()
    {
        $response = $this->getJson('/api/catalog/categories');
        
        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'data' => [
                '*' => [
                    'id',
                    'name',
                    'description',
                ]
            ]
        ]);
    }

    /**
     * Test 2: Smoke Test - User Registration (POST /api/auth/register)
     * @test
     */
    public function test_user_registration_endpoint()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'New User',
            'email' => 'newuser@test.com',
            'phone' => '083456789012',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'CUSTOMER',
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'success',
            'data' => [
                'id',
                'name',
                'email',
                'role',
                'token',
            ]
        ]);
    }

    /**
     * Test 3: Smoke Test - User Login (POST /api/auth/login)
     * @test
     */
    public function test_user_login_endpoint()
    {
        $user = User::where('email', 'customer@test.com')->first();

        $response = $this->postJson('/api/auth/login', [
            'email' => 'customer@test.com',
            'password' => 'password',
        ]);

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'data' => [
                'user' => [
                    'id',
                    'name',
                    'email',
                    'role',
                ],
                'token',
            ]
        ]);
    }

    /**
     * Test 4: Smoke Test - Get Providers (GET /api/catalog/providers)
     * @test
     */
    public function test_providers_list_endpoint()
    {
        $response = $this->getJson('/api/catalog/providers');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'data' => [
                '*' => [
                    'id',
                    'name',
                    'email',
                    'phone',
                ]
            ]
        ]);
    }

    /**
     * Test 5: Smoke Test - Get Provider Detail (GET /api/catalog/providers/{id})
     * @test
     */
    public function test_provider_detail_endpoint()
    {
        $provider = User::where('role', 'PROVIDER')->first();

        $response = $this->getJson("/api/catalog/providers/{$provider->id}");

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'data' => [
                'id',
                'name',
                'email',
                'phone',
            ]
        ]);
    }

    /**
     * Test 6: Smoke Test - Create Order (POST /api/orders)
     * Requires authentication
     * @test
     */
    public function test_create_order_endpoint()
    {
        $customer = User::where('email', 'customer@test.com')->first();
        $provider = User::where('role', 'PROVIDER')->first();
        $service = ProviderService::first();

        // Login as customer
        $loginResponse = $this->postJson('/api/auth/login', [
            'email' => 'customer@test.com',
            'password' => 'password',
        ]);

        $token = $loginResponse->json('data.token');

        $response = $this->withHeaders([
            'Authorization' => "Bearer $token",
        ])->postJson('/api/orders', [
            'provider_id' => $provider->id,
            'service_id' => $service->id,
            'scheduled_date' => now()->addDays(7)->format('Y-m-d'),
            'scheduled_time' => '10:00',
            'location' => 'Jakarta Selatan',
            'description' => 'Need cleaning service',
            'estimated_price' => 150000,
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'success',
            'data' => [
                'id',
                'customer_id',
                'provider_id',
                'status',
            ]
        ]);
    }

    /**
     * Test 7: Smoke Test - Get Orders (GET /api/orders)
     * Requires authentication
     * @test
     */
    public function test_get_orders_endpoint()
    {
        $customer = User::where('email', 'customer@test.com')->first();

        $loginResponse = $this->postJson('/api/auth/login', [
            'email' => 'customer@test.com',
            'password' => 'password',
        ]);

        $token = $loginResponse->json('data.token');

        $response = $this->withHeaders([
            'Authorization' => "Bearer $token",
        ])->getJson('/api/orders');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'data' => [
                '*' => [
                    'id',
                    'status',
                    'estimated_price',
                ]
            ]
        ]);
    }

    /**
     * Test 8: Smoke Test - Database Migration Status
     * @test
     */
    public function test_database_migration_status()
    {
        // This command should execute without error
        $this->artisan('migrate:status')
            ->assertSuccessful();
    }

    /**
     * Test 9: Smoke Test - Queue Configuration
     * @test
     */
    public function test_queue_configuration()
    {
        // Verify queue connection is configured
        $queueConnection = config('queue.default');
        $this->assertNotNull($queueConnection);
        
        // Verify queue connection exists in config
        $connections = config('queue.connections');
        $this->assertArrayHasKey($queueConnection, $connections);
    }

    /**
     * Test 10: Smoke Test - Service Catalog Endpoints
     * @test
     */
    public function test_service_catalog_comprehensive()
    {
        // Test categories endpoint
        $response = $this->getJson('/api/catalog/categories');
        $this->assertEquals(200, $response->status());

        // Test providers endpoint
        $response = $this->getJson('/api/catalog/providers');
        $this->assertEquals(200, $response->status());

        // Verify response structure
        $this->assertTrue($response->json('success'));
        $this->assertIsArray($response->json('data'));
    }

    /**
     * Test 11: Smoke Test - Failed Jobs Queue Check
     * @test
     */
    public function test_failed_jobs_tracking()
    {
        // This command should execute without error
        // It checks if there are any failed jobs in the queue
        $this->artisan('queue:failed')
            ->assertSuccessful();
    }

    /**
     * Test 12: Smoke Test - Unauthorized Access
     * Verify security - accessing protected endpoints without token should fail
     * @test
     */
    public function test_unauthorized_access_to_protected_endpoint()
    {
        $response = $this->getJson('/api/orders');

        $response->assertStatus(401);
    }

    /**
     * Test 13: Smoke Test - Invalid Credentials
     * @test
     */
    public function test_invalid_login_credentials()
    {
        $response = $this->postJson('/api/auth/login', [
            'email' => 'nonexistent@test.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401);
    }

    /**
     * Test 14: Smoke Test - Database Connection
     * @test
     */
    public function test_database_connection()
    {
        // This will fail if database is not accessible
        $userCount = User::count();
        $this->assertGreaterThanOrEqual(0, $userCount);
    }

    /**
     * Test 15: Smoke Test - Redis/Cache Configuration
     * @test
     */
    public function test_cache_configuration()
    {
        // Test cache is working
        cache()->put('smoke_test_key', 'smoke_test_value', 60);
        $value = cache()->get('smoke_test_key');
        
        $this->assertEquals('smoke_test_value', $value);
    }
}
