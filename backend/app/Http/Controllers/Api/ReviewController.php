<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Review;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Http\Requests\Review\CreateReviewRequest;
use App\Traits\ApiResponse;

class ReviewController extends Controller
{
  use ApiResponse;
  /**
   * Create review untuk order
   */
  public function createReview(CreateReviewRequest $request, $orderId)
  {
    $user = Auth::user();

    $order = Order::find($orderId);

    if (!$order) {
      return $this->error('Order not found', 404);
    }

    if ($order->customer_id !== $user->id) {
      return $this->error('Unauthorized', 403);
    }

    // Spec requires reviews only when order is CLOSED
    if ($order->status !== 'CLOSED') {
      return $this->error('Order must be CLOSED to add a review', 400);
    }

    // Ensure single review per order (also enforced by DB unique index)
    if ($order->review) {
      return $this->error('Review already exists for this order', 400);
    }

    $validated = $request->validated();

    $review = null;

    DB::transaction(function () use ($order, $user, $validated, &$review) {
      $review = Review::create([
        'order_id' => $order->id,
        'customer_id' => $user->id,
        'provider_id' => $order->provider_id,
        'rating' => $validated['rating'],
        'comment' => $validated['comment'] ?? null,
      ]);

      $providerProfile = $order->provider->providerProfile;
      if ($providerProfile) {
        $avgRating = Review::where('provider_id', $order->provider_id)->avg('rating');
        $providerProfile->update(['avg_rating' => round($avgRating, 2)]);
      }
    });

    return $this->success($review, 'Review created', 201);
  }

  /**
   * Get reviews untuk provider
   */
  public function getProviderReviews($providerId)
  {
    $perPage = request()->query('per_page', 20);

    $reviews = Review::where('provider_id', $providerId)
      ->with(['customer', 'order'])
      ->latest()
      ->paginate($perPage);

    return $this->paginated($reviews, 'Provider reviews');
  }

  /**
   * Get review untuk order
   */
  public function getOrderReview($orderId)
  {
    $review = Review::where('order_id', $orderId)
      ->with(['customer', 'provider'])
      ->first();

    if (!$review) {
      return $this->notFound('Review not found');
    }

    return $this->success($review, 'Order review');
  }
}
