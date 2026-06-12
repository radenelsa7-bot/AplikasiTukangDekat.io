<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceCategory;
use App\Models\ProviderProfile;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    /**
     * Get semua service categories
     */
    public function getCategories()
    {
        $categories = ServiceCategory::where('is_active', true)->get();

        return $this->successResponse(['categories' => $categories], 'ok', 200);
    }

    /**
     * Get providers berdasarkan category
     */
    public function getProvidersByCategory($categoryId)
    {
        $category = ServiceCategory::find($categoryId);

        if (!$category) {
            return $this->notFoundResponse('category not found');
        }

        $providers = ProviderProfile::whereHas('services', function ($query) use ($categoryId) {
            $query->where('category_id', $categoryId)->where('is_active', true);
        })
            ->where('is_verified', true)
            ->with(['services' => function ($query) use ($categoryId) {
                $query->where('category_id', $categoryId)->where('is_active', true);
            }])
            ->get();

        return $this->successResponse(['providers' => $providers], 'ok', 200);
    }

    /**
     * Get detail provider
     */
    public function getProviderDetail($providerId)
    {
        $provider = ProviderProfile::with(['services' => function ($query) {
            $query->where('is_active', true);
        }, 'user'])
            ->find($providerId);

        if (!$provider) {
            return $this->notFoundResponse('provider not found');
        }

        return $this->successResponse(['provider' => $provider], 'ok', 200);
    }

    /**
     * Search providers (by name atau area)
     */
    public function searchProviders(Request $request)
    {
        $query = $request->query('q', '');

        if (empty($query)) {
            return $this->errorResponse('Query parameter q is required.', 400);
        }

        $providers = ProviderProfile::where('is_verified', true)
            ->where(function ($q) use ($query) {
                $q->where('business_name', 'like', "%$query%")
                    ->orWhere('area', 'like', "%$query%")
                    ->orWhereHas('user', function ($userQ) use ($query) {
                        $userQ->where('name', 'like', "%$query%");
                    });
            })
            ->with('services')
            ->get();

        return $this->successResponse(['providers' => $providers], 'ok', 200);
    }
}
