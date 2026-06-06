<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\ProviderProfile;
use App\Models\Review;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReviewRatingApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_create_review_for_completed_order_and_provider_avg_rating_updates(): void
    {
        $customer = User::factory()->create(['role' => 'CUSTOMER']);
        $provider = User::factory()->create(['role' => 'PROVIDER']);
        ProviderProfile::factory()->create(['user_id' => $provider->id]);

        $category = ServiceCategory::factory()->create();

        $order = Order::create([
            'order_code' => 'ORD-' . now()->format('Ymd') . '-0001',
            'customer_id' => $customer->id,
            'provider_id' => $provider->id,
            'category_id' => $category->id,
            'schedule_at' => now()->addDay(),
            'address' => 'Jl. Test 123',
            'estimated_price' => 150000,
            'final_price' => 150000,
            'status' => 'COMPLETED',
        ]);

        $response = $this->actingAs($customer, 'sanctum')
            ->postJson("/api/reviews/order/{$order->id}", [
                'rating' => 5,
                'comment' => 'Great work',
            ]);

        $response->assertStatus(201);
        $response->assertJsonPath('data.rating', 5);
        $response->assertJsonPath('data.comment', 'Great work');

        $this->assertDatabaseHas('reviews', [
            'order_id' => $order->id,
            'customer_id' => $customer->id,
            'provider_id' => $provider->id,
            'rating' => 5,
        ]);

        $this->assertSame(5.0, (float) $provider->providerProfile->refresh()->avg_rating);
    }

    public function test_get_provider_review_summary_returns_correct_rating_distribution(): void
    {
        $customer = User::factory()->create(['role' => 'CUSTOMER']);
        $provider = User::factory()->create(['role' => 'PROVIDER']);
        ProviderProfile::factory()->create(['user_id' => $provider->id]);
        $category = ServiceCategory::factory()->create();

        $order = Order::create([
            'order_code' => 'ORD-' . now()->format('Ymd') . '-0002',
            'customer_id' => $customer->id,
            'provider_id' => $provider->id,
            'category_id' => $category->id,
            'schedule_at' => now()->addDay(),
            'address' => 'Jl. Test 456',
            'estimated_price' => 100000,
            'final_price' => 100000,
            'status' => 'COMPLETED',
        ]);

        Review::factory()->create([
            'order_id' => $order->id,
            'customer_id' => $customer->id,
            'provider_id' => $provider->id,
            'rating' => 5,
        ]);
        Review::factory()->create([
            'order_id' => $order->id,
            'customer_id' => $customer->id,
            'provider_id' => $provider->id,
            'rating' => 4,
        ]);
        Review::factory()->create([
            'order_id' => $order->id,
            'customer_id' => $customer->id,
            'provider_id' => $provider->id,
            'rating' => 3,
        ]);

        $response = $this->actingAs($customer, 'sanctum')
            ->getJson("/api/reviews/provider/{$provider->id}/summary");

        $response->assertStatus(200)
            ->assertJsonPath('data.provider_id', $provider->id)
            ->assertJsonPath('data.average_rating', 4.0)
            ->assertJsonPath('data.total_reviews', 3)
            ->assertJsonPath('data.distribution.5', 1)
            ->assertJsonPath('data.distribution.4', 1)
            ->assertJsonPath('data.distribution.3', 1)
            ->assertJsonPath('data.distribution.2', 0)
            ->assertJsonPath('data.distribution.1', 0);
    }
}
