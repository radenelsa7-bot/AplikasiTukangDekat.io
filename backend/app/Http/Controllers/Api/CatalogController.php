<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceCategory;
use App\Models\ProviderProfile;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    use ApiResponse;

    /**
     * Get semua service categories
     */
    public function getCategories()
    {
        $categories = ServiceCategory::where('is_active', true)->get();
        return $this->success($categories, 'Categories retrieved');
    }

    /**
     * Get all verified providers
     */
    public function getProviders(Request $request)
    {
        $providers = ProviderProfile::where('is_verified', true)
            ->where('is_active', true)
            ->whereHas('user', fn($query) => $query->where('status', 'ACTIVE'))
            ->with(['user', 'services.category'])
            ->get();

        return $this->success($providers, 'Providers retrieved');
    }

    /**
     * Get providers berdasarkan category
     */
    public function getProvidersByCategory($categoryId)
    {
        $category = ServiceCategory::find($categoryId);

        if (!$category) {
            return $this->notFound('Category not found');
        }

        $providers = ProviderProfile::whereHas('services', function ($query) use ($categoryId) {
            $query->where('category_id', $categoryId)->where('is_active', true);
        })
            ->where('is_verified', true)
            ->where('is_active', true)
            ->whereHas('user', fn($query) => $query->where('status', 'ACTIVE'))
            ->with(['services' => function ($query) use ($categoryId) {
                $query->where('category_id', $categoryId)->where('is_active', true);
            }])
            ->get();

        return $this->success($providers, 'Providers retrieved');
    }

    /**
     * Get detail provider
     */
    public function getProviderDetail($providerId)
    {
        $provider = ProviderProfile::with(['services' => function ($query) {
            $query->where('is_active', true);
        }, 'user'])
            ->where('is_verified', true)
            ->where('is_active', true)
            ->whereHas('user', fn($query) => $query->where('status', 'ACTIVE'))
            ->find($providerId);

        if (!$provider) {
            return $this->notFound('Provider not found');
        }

        return $this->success($provider, 'Provider detail retrieved');
    }

    /**
     * Search providers (by name atau area)
     */
    public function searchProviders(Request $request)
    {
        $query = $request->query('q', '');

        if (empty($query)) {
            return $this->error('Query parameter q is required.', 400);
        }

        $providers = ProviderProfile::where('is_verified', true)
            ->where('is_active', true)
            ->whereHas('user', fn($query) => $query->where('status', 'ACTIVE'))
            ->where(function ($q) use ($query) {
                $q->where('business_name', 'like', "%$query%")
                    ->orWhere('area', 'like', "%$query%")
                    ->orWhereHas('user', function ($userQ) use ($query) {
                        $userQ->where('name', 'like', "%$query%");
                    });
            })
            ->with('services')
            ->get();

        return $this->success($providers, 'Providers found');
    }
}
