<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\ProviderProfile;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class ReviewController extends Controller
{
    use ApiResponse;

    /**
     * Store atau membuat review baru
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'provider_id' => 'required|exists:provider_profiles,id',
            'order_id'    => 'required|exists:orders,id',
            'rating'      => 'required|integer|min:1|max:5',
            'comment'     => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors()->first(), 400);
        }

        $review = Review::create([
            'user_id'     => Auth::id() ?? $request->user_id,
            'provider_id' => $request->provider_id,
            'order_id'    => $request->order_id,
            'rating'      => $request->rating,
            'comment'     => $request->comment,
        ]);

        return $this->successResponse(['review' => $review], 'Review dikirim dengan sukses', 201);
    }

    /**
     * Get reviews untuk provider
     */
    public function getProviderReviews($providerId)
    {
        $perPage = request()->query('per_page', 20);

        $provider = ProviderProfile::find($providerId);
        if (!$provider) {
            return $this->notFoundResponse('Provider tidak ditemukan');
        }

        $reviews = Review::where('provider_id', $providerId)
            ->latest()
            ->paginate($perPage);

        return $this->successResponse(['reviews' => $reviews], 'ok', 200);
    }
}
