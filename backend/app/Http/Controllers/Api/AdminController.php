<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProviderProfile;
use App\Services\N8nNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Traits\ApiResponse;
use App\Http\Requests\Admin\UpdateVerificationRequest;

class AdminController extends Controller
{
  use ApiResponse;

  public function getPendingProviders(Request $request)
  {
    $providers = ProviderProfile::with('user')
      ->where('is_verified', false)
      ->latest()
      ->get();

    return $this->success($providers, 'Pending providers');
  }

  public function updateVerification(UpdateVerificationRequest $request, $providerId)
  {
    $validated = $request->validated();

    $provider = ProviderProfile::with('user')->find($providerId);

    if (!$provider) {
      return $this->notFound('Provider not found');
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

    return $this->success($provider, 'Verification updated');
  }
}
