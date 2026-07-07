<?php

namespace Tests\Feature;

use App\Models\ProviderProfile;
use App\Models\ProviderService;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProviderServiceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_provider_can_create_service(): void
    {
        $category = ServiceCategory::create([
            'name' => 'Electrical',
            'description' => 'Layanan listrik',
            'icon' => 'electric.svg',
        ]);

        $provider = User::factory()->create([
            'role' => 'PROVIDER',
            'status' => 'ACTIVE',
        ]);

        $profile = ProviderProfile::create([
            'user_id' => $provider->id,
            'business_name' => 'Tukang Listrik',
            'is_verified' => true,
        ]);

        $token = $provider->createToken('api-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/provider/services', [
                'category_id' => $category->id,
                'name' => 'Pasang Lampu',
                'base_price' => 150000,
                'price_unit' => 'per kunjungan',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.service_id', 1)
            ->assertJsonPath('message', 'Service created successfully');

        $this->assertDatabaseHas('provider_services', [
            'provider_profile_id' => $profile->id,
            'name' => 'Pasang Lampu',
        ]);
    }

    public function test_provider_can_update_own_service(): void
    {
        $category = ServiceCategory::create([
            'name' => 'Electrical',
            'description' => 'Layanan listrik',
            'icon' => 'electric.svg',
        ]);

        $provider = User::factory()->create([
            'role' => 'PROVIDER',
            'status' => 'ACTIVE',
        ]);

        $profile = ProviderProfile::create([
            'user_id' => $provider->id,
            'business_name' => 'Tukang Listrik',
            'is_verified' => true,
        ]);

        $service = ProviderService::create([
            'provider_profile_id' => $profile->id,
            'category_id' => $category->id,
            'name' => 'Pasang Lampu',
            'base_price' => 150000,
            'price_unit' => 'per kunjungan',
            'is_active' => true,
        ]);

        $token = $provider->createToken('api-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->patchJson("/api/provider/services/{$service->id}", [
                'name' => 'Perbaikan Listrik',
                'base_price' => 175000,
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('message', 'Service updated successfully')
            ->assertJsonPath('data.service.name', 'Perbaikan Listrik')
            ->assertJsonPath('data.service.base_price', 175000);

        $this->assertDatabaseHas('provider_services', [
            'id' => $service->id,
            'name' => 'Perbaikan Listrik',
            'base_price' => 175000,
        ]);
    }

    public function test_provider_cannot_update_other_provider_service(): void
    {
        $category = ServiceCategory::create([
            'name' => 'Electrical',
            'description' => 'Layanan listrik',
            'icon' => 'electric.svg',
        ]);

        $provider1 = User::factory()->create([ 'role' => 'PROVIDER', 'status' => 'ACTIVE' ]);
        $provider2 = User::factory()->create([ 'role' => 'PROVIDER', 'status' => 'ACTIVE' ]);

        $profile1 = ProviderProfile::create([ 'user_id' => $provider1->id, 'business_name' => 'Tukang A', 'is_verified' => true ]);
        $profile2 = ProviderProfile::create([ 'user_id' => $provider2->id, 'business_name' => 'Tukang B', 'is_verified' => true ]);

        $service = ProviderService::create([
            'provider_profile_id' => $profile2->id,
            'category_id' => $category->id,
            'name' => 'Service B',
            'base_price' => 100000,
            'price_unit' => 'per jam',
            'is_active' => true,
        ]);

        $token = $provider1->createToken('api-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->patchJson("/api/provider/services/{$service->id}", [
                'name' => 'Hack',
            ]);

        $response->assertStatus(404);
    }
}
