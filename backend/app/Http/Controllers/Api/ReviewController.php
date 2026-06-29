<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\ProviderProfile;
use App\Models\Review;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class ReviewController extends Controller
{
    use ApiResponse;

    public function createReview(Request $request, $orderId)
    {
        $validator = Validator::make($request->all() + ['order_id' => $orderId], [
            'order_id' => 'required|exists:orders,id',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors()->first(), 400);
        }

        $order = Order::find($orderId);
        if (!$order) {
            return $this->notFoundResponse('Order tidak ditemukan');
        }

        if (!in_array($order->status, ['COMPLETED', 'CLOSED'], true)) {
            return $this->errorResponse('Order harus berstatus COMPLETED atau CLOSED sebelum review dibuat.', 422);
        }

        $existingReview = Review::where('order_id', $orderId)
            ->where('customer_id', Auth::id())
            ->exists();

        if ($existingReview) {
            return $this->errorResponse('Anda sudah memberikan review untuk order ini.', 409);
        }

        $review = Review::create([
            'customer_id' => Auth::id(),
            'provider_id' => $order->provider_id,
            'order_id' => $order->id,
            'rating' => (int) $request->input('rating'),
            'comment' => $request->input('comment'),
        ]);

        $this->updateProviderAvgRating($order->provider_id);

        return $this->successResponse(['review' => $review], 'Review dikirim dengan sukses', 201);
    }

    public function store(Request $request)
    {
        return $this->createReview($request, $request->input('order_id'));
    }

    public function getProviderReviews($providerId)
    {
        $perPage = (int) request()->query('per_page', 20);

        $provider = ProviderProfile::find($providerId);
        if (!$provider) {
            return $this->notFoundResponse('Provider tidak ditemukan');
        }

        $reviews = Review::where('provider_id', $providerId)
            ->latest()
            ->paginate($perPage);

        return $this->successResponse(['reviews' => $reviews], 'ok', 200);
    }

    public function getOrderReview($orderId)
    {
        $review = Review::where('order_id', $orderId)->first();

        if (!$review) {
            return $this->notFoundResponse('Review tidak ditemukan');
        }

        return $this->successResponse(['review' => $review], 'ok', 200);
    }

    private function updateProviderAvgRating($providerId): void
    {
        $provider = ProviderProfile::find($providerId);
        if (!$provider) {
            return;
        }

        $average = Review::where('provider_id', $providerId)->avg('rating');
        $provider->avg_rating = round((float) $average, 1);
        $provider->save();
    }
}
