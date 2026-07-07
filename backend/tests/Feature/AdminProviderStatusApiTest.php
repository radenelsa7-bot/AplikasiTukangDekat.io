<?php

namespace Tests\Feature;

use App\Models\ProviderProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminProviderStatusApiTest extends TestCase
{
  use RefreshDatabase;

public function test_admin_can_disable_and_enable_provider_profile(): void
    {
      $admin = User::factory()->create(['role' => 'ADMIN']);
      $provider = User::factory()->create(['role' => 'PROVIDER']);
      $profile = ProviderProfile::create([
        'user_id' => $provider->id,
        'business_name' => 'Test Provider',
        'is_verified' => true,
        'is_active' => true,
      ]);

      $disableResponse = $this->actingAs($admin, 'sanctum')
        ->postJson("/api/admin/providers/{$provider->id}/disable");

      $disableResponse->assertStatus(200)
        ->assertJsonPath('data.status', 'SUSPENDED');

      $this->assertDatabaseHas('provider_profiles', [
        'id' => $profile->id,
        'is_verified' => false,
        'is_active' => false,
      ]);

      $enableResponse = $this->actingAs($admin, 'sanctum')
        ->postJson("/api/admin/providers/{$provider->id}/enable");

      $enableResponse->assertStatus(200)
        ->assertJsonPath('data.status', 'ACTIVE');

      $this->assertDatabaseHas('provider_profiles', [
        'id' => $profile->id,
        'is_verified' => true,
        'is_active' => true,
    ]);
  }
}
