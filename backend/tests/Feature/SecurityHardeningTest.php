<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SecurityHardeningTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_route_is_forbidden_for_non_admin_users(): void
    {
        $user = User::factory()->create([
            'email' => 'not-admin@example.com',
            'password' => 'password',
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $token = $user->createToken('role-test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/admin/providers/pending');

        $this->assertSame(403, $response->status());
        $this->assertSame('only admin can access this resource', $response->json('message'));
    }

    public function test_treasurer_route_is_forbidden_for_non_treasurer_users(): void
    {
        $user = User::factory()->create([
            'email' => 'not-treasurer@example.com',
            'password' => 'password',
            'role' => 'CUSTOMER',
            'status' => 'ACTIVE',
        ]);

        $token = $user->createToken('role-test-2')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/treasurer/payments/report');

        $this->assertSame(403, $response->status());
        $this->assertSame('only treasurer can access this resource', $response->json('message'));
    }
}
