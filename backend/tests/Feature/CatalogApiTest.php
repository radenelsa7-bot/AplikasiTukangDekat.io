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
    $activeProvider = User::factory()->create(['role' => 'PROVIDER']);
    ProviderProfile::factory()->create([
      'user_id' => $activeProvider->id,
      'business_name' => 'Active Provider',
      'is_verified' => true,
      'is_active' => true,
    ]);

    $inactiveProvider = User::factory()->create(['role' => 'PROVIDER']);
    ProviderProfile::factory()->create([
      'user_id' => $inactiveProvider->id,
      'business_name' => 'Inactive Provider',
      'is_verified' => true,
      'is_active' => false,
    ]);

    $response = $this->getJson('/api/catalog/providers');

    $response->assertStatus(200)
      ->assertJsonCount(1, 'data.providers')
      ->assertJsonPath('data.providers.0.business_name', 'Active Provider');
  }
}
