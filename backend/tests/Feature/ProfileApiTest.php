<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProfileApiTest extends TestCase
{
  use RefreshDatabase;

  public function test_update_profile_with_photo_upload(): void
  {
    Storage::fake('public');

    $user = User::factory()->create([
      'email' => 'user@example.com',
      'role' => 'CUSTOMER',
      'status' => 'ACTIVE',
    ]);

    $token = $user->createToken('api-token')->plainTextToken;

    // Use create() instead of image() to avoid GD library dependency
    $photoFile = UploadedFile::fake()->create('profile.jpg', 500, 'image/jpeg');

    $response = $this->withHeader('Authorization', "Bearer {$token}")
      ->postJson('/api/profile/update', [
        'full_name' => 'John Doe Updated',
        'phone_number' => '081234567890',
        'profile_photo' => $photoFile,
      ]);

    $response->assertStatus(200)
      ->assertJsonStructure([
        'success',
        'message',
        'data' => [
          'user' => [
            'id',
            'name',
            'email',
            'role',
            'full_name',
            'phone',
            'phone_number',
            'profile_photo_path',
          ],
        ],
      ])
      ->assertJsonPath('message', 'Profile updated successfully')
      ->assertJsonPath('data.user.full_name', 'John Doe Updated')
      ->assertJsonPath('data.user.phone_number', '081234567890');

    $user->refresh();
    $this->assertNotNull($user->profile_photo_path);
    $this->assertStringContainsString('profiles', $user->profile_photo_path);
    Storage::disk('public')->assertExists($user->profile_photo_path);
  }

  public function test_update_profile_without_photo(): void
  {
    $user = User::factory()->create([
      'email' => 'user2@example.com',
      'role' => 'CUSTOMER',
      'status' => 'ACTIVE',
    ]);

    $token = $user->createToken('api-token')->plainTextToken;

    $response = $this->withHeader('Authorization', "Bearer {$token}")
      ->postJson('/api/profile/update', [
        'full_name' => 'Jane Doe',
        'phone_number' => '082345678901',
      ]);

    if ($response->status() !== 200) {
      dump('Response:', $response->json());
      dump('Status:', $response->status());
    }

    $response->assertStatus(200)
      ->assertJsonPath('data.user.full_name', 'Jane Doe')
      ->assertJsonPath('data.user.phone_number', '082345678901');

    $user->refresh();
    $this->assertEquals('Jane Doe', $user->full_name);
    $this->assertEquals('082345678901', $user->phone_number);
  }

  public function test_delete_profile_photo_successfully(): void
  {
    Storage::fake('public');

    $user = User::factory()->create([
      'email' => 'user3@example.com',
      'profile_photo_path' => 'profiles/user_photo.jpg',
      'role' => 'CUSTOMER',
      'status' => 'ACTIVE',
    ]);

    $token = $user->createToken('api-token')->plainTextToken;

    $response = $this->withHeader('Authorization', "Bearer {$token}")
      ->deleteJson('/api/profile/photo');

    $response->assertStatus(200)
      ->assertJsonStructure([
        'success',
        'message',
        'data' => [
          'user' => [
            'id',
            'name',
            'email',
            'role',
            'full_name',
            'phone',
            'phone_number',
            'profile_photo_path',
          ],
        ],
      ])
      ->assertJsonPath('message', 'Profile photo deleted successfully')
      ->assertJsonPath('data.user.profile_photo_path', null);

    $user->refresh();
    $this->assertNull($user->profile_photo_path);
  }

  public function test_delete_profile_photo_when_no_photo_exists(): void
  {
    $user = User::factory()->create([
      'email' => 'user4@example.com',
      'profile_photo_path' => null,
      'role' => 'CUSTOMER',
      'status' => 'ACTIVE',
    ]);

    $token = $user->createToken('api-token')->plainTextToken;

    $response = $this->withHeader('Authorization', "Bearer {$token}")
      ->deleteJson('/api/profile/photo');

    $response->assertStatus(200)
      ->assertJsonPath('message', 'Profile photo deleted successfully')
      ->assertJsonPath('data.user.profile_photo_path', null);

    $user->refresh();
    $this->assertNull($user->profile_photo_path);
  }

  public function test_update_profile_validation_phone_number(): void
  {
    $user = User::factory()->create([
      'email' => 'user5@example.com',
      'role' => 'CUSTOMER',
      'status' => 'ACTIVE',
    ]);

    $token = $user->createToken('api-token')->plainTextToken;

    // Test dengan phone number terlalu pendek
    $response = $this->withHeader('Authorization', "Bearer {$token}")
      ->postJson('/api/profile/update', [
        'phone_number' => '12345',
      ]);

    $response->assertStatus(422)
      ->assertJsonPath('success', false)
      ->assertJsonPath('error_code', 'VALIDATION_ERROR');
  }

  public function test_update_profile_validation_photo_max_size(): void
  {
    Storage::fake('public');

    $user = User::factory()->create([
      'email' => 'user6@example.com',
      'role' => 'CUSTOMER',
      'status' => 'ACTIVE',
    ]);

    $token = $user->createToken('api-token')->plainTextToken;

    // Create a file larger than 2MB
    $largeFile = UploadedFile::fake()->create('large.jpg', 3000, 'image/jpeg');

    $response = $this->withHeader('Authorization', "Bearer {$token}")
      ->postJson('/api/profile/update', [
        'profile_photo' => $largeFile,
      ]);

    $response->assertStatus(422)
      ->assertJsonPath('success', false)
      ->assertJsonPath('error_code', 'VALIDATION_ERROR');
  }

  public function test_update_profile_requires_authentication(): void
  {
    $response = $this->postJson('/api/profile/update', [
      'full_name' => 'Unauthorized User',
    ]);

    $response->assertStatus(401);
  }

  public function test_delete_profile_photo_requires_authentication(): void
  {
    $response = $this->deleteJson('/api/profile/photo');

    $response->assertStatus(401);
  }
}
