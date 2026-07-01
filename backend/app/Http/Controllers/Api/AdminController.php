<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateVerificationRequest;
use App\Models\ProviderProfile;
use App\Models\User;
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

        return $this->success($providers, 'Pending providers');
    }

    public function updateVerification(UpdateVerificationRequest $request, $providerId)
    {
        if ($response = $this->ensureAdmin()) {
            return $response;
        }

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

    public function disableProvider(Request $request, $providerId)
    {
        if ($response = $this->ensureAdmin()) {
            return $response;
        }

        $request->validate([
            'reason' => 'nullable|string|max:500',
        ]);

        $provider = User::where('id', $providerId)->where('role', 'PROVIDER')->first();

        if (!$provider) {
            return $this->notFound('Provider not found');
        }

        if ($provider->status === 'SUSPENDED') {
            return $this->conflict('Provider is already disabled');
        }

        $provider->update(['status' => 'SUSPENDED']);

        $profile = ProviderProfile::where('user_id', $providerId)->first();
        if ($profile) {
            $profile->update(['is_verified' => false]);
        }

        app(N8nNotificationService::class)->dispatch('provider_disabled', [
            'provider_id' => $providerId,
            'provider_name' => $provider->name,
            'reason' => $request->input('reason', 'Policy violation'),
        ]);

        return $this->success([
            'provider_id' => $provider->id,
            'status' => $provider->status,
        ], 'Provider disabled');
    }

    public function enableProvider(Request $request, $providerId)
    {
        if ($response = $this->ensureAdmin()) {
            return $response;
        }

        $provider = User::where('id', $providerId)->where('role', 'PROVIDER')->first();

        if (!$provider) {
            return $this->notFound('Provider not found');
        }

        if ($provider->status === 'ACTIVE') {
            return $this->conflict('Provider is already active');
        }

        $provider->update(['status' => 'ACTIVE']);

        app(N8nNotificationService::class)->dispatch('provider_enabled', [
            'provider_id' => $providerId,
            'provider_name' => $provider->name,
        ]);

        return $this->success([
            'provider_id' => $provider->id,
            'status' => $provider->status,
        ], 'Provider enabled');
    }
}
