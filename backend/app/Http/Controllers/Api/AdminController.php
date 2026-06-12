<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProviderProfile;
use App\Services\N8nNotificationService;
use Illuminate\Http\Request;

class AdminController extends Controller
{
  public function getPendingProviders(Request $request)
  {

    $providers = ProviderProfile::with('user')
      ->where('is_verified', false)
      ->latest()
      ->get();

    return response()->json([
      'data' => $providers,
    ], 200);
  }

  public function updateVerification(Request $request, $providerId)
  {
    $validated = $request->validate([
      'is_verified' => 'required|boolean',
    ]);

    $provider = ProviderProfile::with('user')->find($providerId);

    if (!$provider) {
      return response()->json([
        'message' => 'provider not found',
      ], 404);
    }

    $provider->update([
      'is_verified' => $validated['is_verified'],
    ]);

    app(N8nNotificationService::class)->dispatch(
      $validated['is_verified'] ? 'provider_verified' : 'provider_unverified',
      [
        'provider_id' => $provider->id,
        'user_id' => $provider->user_id,
        'business_name' => $provider->business_name,
        'area' => $provider->area,
        'is_verified' => $provider->is_verified,
      ]
    );

    return response()->json([
      'message' => 'verification updated',
      'data' => $provider,
    ], 200);
  }
}
