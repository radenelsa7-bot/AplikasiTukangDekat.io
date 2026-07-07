<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateProfileRequest;
use App\Models\ProviderProfile;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

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
        ]);

        $profile = ProviderProfile::firstOrCreate(
            ['user_id' => $user->id],
            ['is_verified' => false]
        );

        $profile->update($request->only(['business_name', 'description', 'area', 'address']));

        return $this->success([
            'profile' => $profile->fresh(['services.category']),
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
            'profile' => $profile->fresh(['services.category']),
        ], 'Provider profile retrieved successfully', 200);
    }
}
