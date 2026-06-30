<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateVerificationRequest;
use App\Models\ProviderProfile;
use App\Services\N8nNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Traits\ApiResponse;

class AdminController extends Controller
{
  use ApiResponse;
  private function ensureAdmin(): ?\Illuminate\Http\JsonResponse
  {
    $user = Auth::user();

    if (!$user || $user->role !== 'ADMIN') {
      return $this->forbiddenResponse('only admin can access this resource');
    }

    return null;
  }

  public function getPendingProviders(Request $request)
  {

    $providers = ProviderProfile::with('user')
      ->where('is_verified', false)
      ->latest()
      ->get();

    return $this->successResponse(['providers' => $providers], 'ok', 200);
  }

  public function updateVerification(UpdateVerificationRequest $request, $providerId)
  {
    if ($response = $this->ensureAdmin()) {
      return $response;
    }

    $validated = $request->validated();

    $provider = ProviderProfile::with('user')->find($providerId);

    if (!$provider) {
      return $this->notFoundResponse('provider not found');
    }

    $provider->update([
      'is_verified' => $validated['is_verified'],
      'is_active' => $provider->is_active ?? true,
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

    return $this->successResponse($provider, 'verification updated', 200);
  }

  public function deactivateProvider($providerId)
  {
    if ($response = $this->ensureAdmin()) {
      return $response;
    }

    $provider = ProviderProfile::find($providerId);

    if (!$provider) {
      return $this->notFoundResponse('provider not found');
    }

    $provider->update(['is_active' => false]);

    return $this->successResponse($provider, 'provider deactivated', 200);
  }
}
