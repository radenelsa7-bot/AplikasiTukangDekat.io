<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceCategory;
use App\Models\ProviderProfile;
use App\Models\WilayahKecamatan;
use App\Models\WilayahKota;
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

    public function getKota()
    {
        $kota = WilayahKota::orderBy('name')->get();
        return $this->success($kota, 'Cities retrieved');
    }

    public function getKecamatan(int $kotaId)
    {
        $kecamatan = WilayahKecamatan::where('kota_id', $kotaId)
            ->orderBy('name')
            ->get();

        return $this->success($kecamatan, 'Districts retrieved');
    }

    /**
     * Get all verified providers
     */
    public function getProviders(Request $request)
    {
        $providers = ProviderProfile::where('is_verified', true)
            ->with(['user', 'services.category'])
            ->get();

        return $this->success($this->withAvailability($providers), 'Providers retrieved');
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
            ->with(['services' => function ($query) use ($categoryId) {
                $query->where('category_id', $categoryId)->where('is_active', true);
            }])
            ->get();

        return $this->success($this->withAvailability($providers), 'Providers retrieved');
    }

    /**
     * Get detail provider
     */
    public function getProviderDetail($providerId)
    {
        $provider = ProviderProfile::with(['services' => function ($query) {
            $query->where('is_active', true);
        }, 'user'])->find($providerId);

        if (!$provider) {
            return $this->notFound('Provider not found');
        }

        return $this->success($this->withAvailability(collect([$provider]))->first(), 'Provider detail retrieved');
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
            ->where(function ($q) use ($query) {
                $q->where('business_name', 'like', "%$query%")
                    ->orWhere('area', 'like', "%$query%")
                    ->orWhereHas('user', function ($userQ) use ($query) {
                        $userQ->where('name', 'like', "%$query%");
                    });
            })
            ->with('services')
            ->get();

        return $this->success($this->withAvailability($providers), 'Providers found');
    }

    private function withAvailability($providers)
    {
        $providerUserIds = $providers->pluck('user_id')->filter()->values();
        $busyProviderIds = Order::whereIn('provider_id', $providerUserIds)
            ->whereIn('status', ['ACCEPTED', 'IN_PROGRESS'])
            ->pluck('provider_id')
            ->all();

        return $providers->map(function ($provider) use ($busyProviderIds) {
            $provider->availability_status = in_array($provider->user_id, $busyProviderIds, true)
                ? 'BUSY'
                : ($provider->availability_status ?: 'AVAILABLE');
            return $provider;
        });
    }
}
