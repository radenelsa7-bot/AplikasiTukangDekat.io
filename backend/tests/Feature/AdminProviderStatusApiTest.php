<?php

namespace Tests\Feature;

use App\Models\ProviderProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminProviderStatusApiTest extends TestCase
{
  use RefreshDatabase;

  public function test_admin_can_deactivate_provider_profile(): void
  {
    $admin = User::factory()->create(['role' => 'ADMIN']);
    $provider = User::factory()->create(['role' => 'PROVIDER']);
    $profile = ProviderProfile::create([
      'user_id' => $provider->id,
      'business_name' => 'Test Provider',
      'is_verified' => true,
      'is_active' => true,
    ]);

    $response = $this->actingAs($admin, 'sanctum')
      ->postJson("/api/admin/providers/{$profile->id}/deactivate");

    $response->assertStatus(200)
      ->assertJsonPath('data.is_active', false);

    $this->assertDatabaseHas('provider_profiles', [
      'id' => $profile->id,
      'is_active' => false,
    ]);
  }
}
