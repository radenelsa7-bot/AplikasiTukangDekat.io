<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateProfileRequest;
use App\Models\Order;
use App\Models\Payment;
use App\Models\ProviderCoverage;
use App\Models\ProviderProfile;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    use ApiResponse;

    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validated();

        if (array_key_exists('full_name', $validated)) {
            $user->full_name = $validated['full_name'];
        }

        if (array_key_exists('phone_number', $validated)) {
            $user->phone_number = $validated['phone_number'];
        }

        if ($request->hasFile('profile_photo')) {
            if ($user->profile_photo_path) {
                Storage::disk('public')->delete($user->profile_photo_path);
            }

            $profilePhoto = $request->file('profile_photo');
            $fileName = sprintf('%s_%s.%s', $user->id, uniqid(), $profilePhoto->getClientOriginalExtension());
            $user->profile_photo_path = Storage::disk('public')->putFileAs('profiles', $profilePhoto, $fileName);
        }

        $user->save();

        return $this->success([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'full_name' => $user->full_name,
                'phone' => $user->phone,
                'phone_number' => $user->phone_number,
                'profile_photo_path' => $user->profile_photo_path,
            ],
        ], 'Profile updated successfully', 200);
    }

    public function deleteProfilePhoto(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->profile_photo_path) {
            Storage::disk('public')->delete($user->profile_photo_path);
            $user->profile_photo_path = null;
            $user->save();
        }

        return $this->success([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'full_name' => $user->full_name,
                'phone' => $user->phone,
                'phone_number' => $user->phone_number,
                'profile_photo_path' => $user->profile_photo_path,
            ],
        ], 'Profile photo deleted successfully', 200);
    }

    public function updateProviderProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'PROVIDER') {
            return $this->forbidden('Only providers can update provider profiles');
        }

        $request->validate([
            'business_name' => 'nullable|string|max:150',
            'description' => 'nullable|string|max:2000',
            'area' => 'nullable|string|max:100',
            'address' => 'nullable|string|max:500',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
        ]);

        $profile = ProviderProfile::firstOrCreate(
            ['user_id' => $user->id],
            ['is_verified' => false]
        );

        $profile->update($request->only(['business_name', 'description', 'area', 'address', 'latitude', 'longitude']));

        return $this->success([
            'profile' => $profile->fresh(['services.category', 'coverages.kecamatan.kota']),
        ], 'Provider profile updated successfully', 200);
    }

    public function getProviderProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'PROVIDER') {
            return $this->forbidden('Only providers can access this resource');
        }

        $profile = ProviderProfile::with(['services.category'])
            ->firstOrCreate([
                'user_id' => $user->id,
            ], [
                'is_verified' => false,
            ]);

        return $this->success([
            'profile' => $profile->fresh(['services.category', 'coverages.kecamatan.kota']),
        ], 'Provider profile retrieved successfully', 200);
    }

    public function getProviderCoverage(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'PROVIDER') {
            return $this->forbidden('Only providers can access this resource');
        }

        $profile = ProviderProfile::with(['coverages.kecamatan.kota'])
            ->firstOrCreate([
                'user_id' => $user->id,
            ], [
                'is_verified' => false,
            ]);

        return $this->success([
            'profile' => $profile,
        ], 'Provider coverage retrieved successfully', 200);
    }

    public function updateProviderCoverage(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'PROVIDER') {
            return $this->forbidden('Only providers can update coverage');
        }

        $validated = $request->validate([
            'kota_id' => 'required|integer|exists:wilayah_kota,id',
            'kecamatan_ids' => 'required|array|min:1',
            'kecamatan_ids.*' => [
                'required',
                'integer',
                Rule::exists('wilayah_kecamatan', 'id')->where(function ($query) use ($request) {
                    $query->where('kota_id', $request->integer('kota_id'));
                }),
            ],
        ]);

        $profile = ProviderProfile::firstOrCreate(
            ['user_id' => $user->id],
            ['is_verified' => false]
        );

        $kecamatanIds = array_values(array_unique(array_map('intval', $validated['kecamatan_ids'])));

        DB::transaction(function () use ($profile, $validated, $kecamatanIds) {
            ProviderCoverage::where('provider_profile_id', $profile->id)
                ->whereHas('kecamatan', function ($query) use ($validated) {
                    $query->where('kota_id', $validated['kota_id']);
                })
                ->delete();

            foreach ($kecamatanIds as $kecamatanId) {
                ProviderCoverage::updateOrCreate(
                    [
                        'provider_profile_id' => $profile->id,
                        'kecamatan_id' => $kecamatanId,
                    ],
                    [
                        'is_active' => true,
                    ]
                );
            }
        });

        return $this->success([
            'profile' => $profile->fresh(['services.category', 'coverages.kecamatan.kota']),
        ], 'Provider coverage updated successfully', 200);
    }

    public function providerDashboard(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'PROVIDER') {
            return $this->forbidden('Only providers can access this resource');
        }

        $providerIds = $this->providerIdentifierSet($user);
        $orders = Order::whereIn('provider_id', $providerIds);
        $activeOrders = (clone $orders)->whereIn('status', ['CREATED', 'ACCEPTED', 'IN_PROGRESS'])->count();
        $completedOrders = (clone $orders)->whereIn('status', ['COMPLETED', 'CLOSED'])->count();

        $paidPayments = Payment::whereHas('order', function ($query) use ($user) {
            $query->whereIn('provider_id', $this->providerIdentifierSet($user));
        })->where('status', 'PAID');

        $grossRevenue = (clone $paidPayments)->sum('amount');
        $providerBalance = (clone $paidPayments)->sum('provider_payout');
        if ($providerBalance <= 0) {
            $providerBalance = (int) round($grossRevenue * 0.9);
        }

        $transactions = (clone $paidPayments)
            ->with('order:id,order_code,customer_id,provider_id,status')
            ->latest()
            ->limit(10)
            ->get();

        return $this->success([
            'balance' => $providerBalance,
            'gross_revenue' => $grossRevenue,
            'active_orders' => $activeOrders,
            'completed_orders' => $completedOrders,
            'transactions' => $transactions,
        ], 'Provider dashboard retrieved successfully', 200);
    }

    private function providerIdentifierSet($user): array
    {
        $ids = [(int) $user->id];
        $profileId = $user->providerProfile?->id;
        if ($profileId) {
            $ids[] = (int) $profileId;
        }

        return array_values(array_unique($ids));
    }
}
