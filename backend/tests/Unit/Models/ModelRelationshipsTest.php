<?php

namespace Tests\Unit\Models;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use App\Models\Review;
use App\Models\Payment;
use App\Models\ProviderProfile;
use App\Models\ProviderService;
use App\Models\ProviderPayout;
use App\Models\ServiceCategory;
use App\Models\OrderAttachment;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ModelRelationshipsTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test User model relationships
     */
    public function test_user_has_provider_profile()
    {
        $user = User::factory()->create();
        $profile = ProviderProfile::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(ProviderProfile::class, $user->providerProfile);
        $this->assertEquals($profile->id, $user->providerProfile->id);
    }

    public function test_user_has_many_customer_orders()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $orders = Order::factory(3)->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertCount(3, $customer->customerOrders);
        $this->assertInstanceOf(Order::class, $customer->customerOrders->first());
    }

    public function test_user_has_many_provider_orders()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        Order::factory(2)->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertCount(2, $provider->providerOrders);
        $this->assertInstanceOf(Order::class, $provider->providerOrders->first());
    }

    public function test_user_has_many_customer_reviews()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order1 = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        $order2 = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        Review::factory()->create(['order_id' => $order1->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);
        Review::factory()->create(['order_id' => $order2->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertCount(2, $customer->customerReviews);
        $this->assertInstanceOf(Review::class, $customer->customerReviews->first());
    }

    public function test_user_has_many_provider_reviews()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order1 = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        $order2 = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        Review::factory()->create(['order_id' => $order1->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);
        Review::factory()->create(['order_id' => $order2->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertCount(2, $provider->providerReviews);
    }

    public function test_user_has_many_payouts()
    {
        $provider = User::factory()->create();
        ProviderPayout::factory(3)->create(['provider_id' => $provider->id]);

        $this->assertCount(3, $provider->payouts);
        $this->assertInstanceOf(ProviderPayout::class, $provider->payouts->first());
    }

    /**
     * Test Order model relationships
     */
    public function test_order_belongs_to_customer()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertInstanceOf(User::class, $order->customer);
        $this->assertEquals($customer->id, $order->customer->id);
    }

    public function test_order_belongs_to_provider()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertInstanceOf(User::class, $order->provider);
        $this->assertEquals($provider->id, $order->provider->id);
    }

    public function test_order_belongs_to_category()
    {
        $category = ServiceCategory::factory()->create();
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order = Order::factory()->create(['category_id' => $category->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertInstanceOf(ServiceCategory::class, $order->category);
        $this->assertEquals($category->id, $order->category->id);
    }

    public function test_order_has_many_payments()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        Payment::factory(2)->create(['order_id' => $order->id]);

        $this->assertCount(2, $order->payments);
        $this->assertInstanceOf(Payment::class, $order->payments->first());
    }

    public function test_order_has_many_attachments()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        OrderAttachment::factory(3)->create(['order_id' => $order->id]);

        $this->assertCount(3, $order->attachments);
        $this->assertInstanceOf(OrderAttachment::class, $order->attachments->first());
    }

    public function test_order_has_one_review()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        $review = Review::factory()->create(['order_id' => $order->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertInstanceOf(Review::class, $order->review);
        $this->assertEquals($review->id, $order->review->id);
    }

    /**
     * Test Review model relationships
     */
    public function test_review_belongs_to_order()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        $review = Review::factory()->create(['order_id' => $order->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertInstanceOf(Order::class, $review->order);
        $this->assertEquals($order->id, $review->order->id);
    }

    public function test_review_belongs_to_customer()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        $review = Review::factory()->create(['order_id' => $order->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertInstanceOf(User::class, $review->customer);
        $this->assertEquals($customer->id, $review->customer->id);
    }

    public function test_review_belongs_to_provider()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        $review = Review::factory()->create(['order_id' => $order->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertInstanceOf(User::class, $review->provider);
        $this->assertEquals($provider->id, $review->provider->id);
    }

    /**
     * Test Payment model relationships
     */
    public function test_payment_belongs_to_order()
    {
        $customer = User::factory()->create();
        $provider = User::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        $payment = Payment::factory()->create(['order_id' => $order->id]);

        $this->assertInstanceOf(Order::class, $payment->order);
        $this->assertEquals($order->id, $payment->order->id);
    }

    /**
     * Test ProviderProfile model relationships
     */
    public function test_provider_profile_belongs_to_user()
    {
        $user = User::factory()->create();
        $profile = ProviderProfile::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(User::class, $profile->user);
        $this->assertEquals($user->id, $profile->user->id);
    }

    public function test_provider_profile_has_many_services()
    {
        $user = User::factory()->create();
        $profile = ProviderProfile::factory()->create(['user_id' => $user->id]);
        ProviderService::factory(3)->create(['provider_profile_id' => $profile->id]);

        $this->assertCount(3, $profile->services);
        $this->assertInstanceOf(ProviderService::class, $profile->services->first());
    }

    public function test_provider_profile_has_many_reviews()
    {
        $provider = User::factory()->create();
        $profile = ProviderProfile::factory()->create(['user_id' => $provider->id]);
        $customer = User::factory()->create();
        $order1 = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        $order2 = Order::factory()->create(['customer_id' => $customer->id, 'provider_id' => $provider->id]);
        Review::factory()->create(['order_id' => $order1->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);
        Review::factory()->create(['order_id' => $order2->id, 'customer_id' => $customer->id, 'provider_id' => $provider->id]);

        $this->assertCount(2, $profile->reviews);
        $this->assertInstanceOf(Review::class, $profile->reviews->first());
    }

    /**
     * Test ProviderService model relationships
     */
    public function test_provider_service_belongs_to_provider_profile()
    {
        $user = User::factory()->create();
        $profile = ProviderProfile::factory()->create(['user_id' => $user->id]);
        $service = ProviderService::factory()->create(['provider_profile_id' => $profile->id]);

        $this->assertInstanceOf(ProviderProfile::class, $service->provider);
        $this->assertEquals($profile->id, $service->provider->id);
    }

    public function test_provider_service_belongs_to_category()
    {
        $category = ServiceCategory::factory()->create();
        $user = User::factory()->create();
        $profile = ProviderProfile::factory()->create(['user_id' => $user->id]);
        $service = ProviderService::factory()->create([
            'provider_profile_id' => $profile->id,
            'category_id' => $category->id
        ]);

        $this->assertInstanceOf(ServiceCategory::class, $service->category);
        $this->assertEquals($category->id, $service->category->id);
    }

    /**
     * Test ServiceCategory model relationships
     */
    public function test_service_category_has_many_provider_services()
    {
        $category = ServiceCategory::factory()->create();
        $user = User::factory()->create();
        $profile = ProviderProfile::factory()->create(['user_id' => $user->id]);
        ProviderService::factory(3)->create(['category_id' => $category->id, 'provider_profile_id' => $profile->id]);

        $this->assertCount(3, $category->providerServices);
        $this->assertInstanceOf(ProviderService::class, $category->providerServices->first());
    }

    /**
     * Test ProviderPayout model relationships
     */
    public function test_provider_payout_belongs_to_provider()
    {
        $provider = User::factory()->create();
        $payout = ProviderPayout::factory()->create(['provider_id' => $provider->id]);

        $this->assertInstanceOf(User::class, $payout->provider);
        $this->assertEquals($provider->id, $payout->provider->id);
    }

    public function test_provider_payout_has_many_attempts()
    {
        $provider = User::factory()->create();
        $payout = ProviderPayout::factory()->create(['provider_id' => $provider->id]);
        \App\Models\ProviderPayoutAttempt::factory(2)->create(['provider_payout_id' => $payout->id]);

        $this->assertCount(2, $payout->attempts);
    }
}
