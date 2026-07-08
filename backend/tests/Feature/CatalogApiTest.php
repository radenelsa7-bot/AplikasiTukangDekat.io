<?php

namespace Tests\Feature;

use App\Models\ProviderProfile;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CatalogApiTest extends TestCase
{
  use RefreshDatabase;

  public function test_inactive_providers_are_not_returned_in_catalog(): void
  {
      $activeProvider = User::factory()->create(['role' => 'PROVIDER', 'status' => 'ACTIVE']);
      ProviderProfile::factory()->create([
        'user_id' => $activeProvider->id,
        'business_name' => 'Active Provider',
        'is_verified' => true,
        'is_active' => true,
      ]);

      $inactiveProvider = User::factory()->create(['role' => 'PROVIDER', 'status' => 'ACTIVE']);
      ProviderProfile::factory()->create([
        'user_id' => $inactiveProvider->id,
        'business_name' => 'Inactive Provider',
        'is_verified' => true,
        'is_active' => false,
      ]);

      $response = $this->getJson('/api/catalog/providers');

      $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.business_name', 'Active Provider');
    }

    public function test_suspended_provider_is_not_returned_in_catalog(): void
    {
        $activeProvider = User::factory()->create(['role' => 'PROVIDER', 'status' => 'ACTIVE']);
        ProviderProfile::factory()->create([
            'user_id' => $activeProvider->id,
            'business_name' => 'Active Provider',
            'is_verified' => true,
            'is_active' => true,
        ]);

        $suspendedProvider = User::factory()->create(['role' => 'PROVIDER', 'status' => 'SUSPENDED']);
        ProviderProfile::factory()->create([
            'user_id' => $suspendedProvider->id,
            'business_name' => 'Suspended Provider',
            'is_verified' => true,
            'is_active' => true,
        ]);

        $response = $this->getJson('/api/catalog/providers');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.business_name', 'Active Provider');
    }
}
