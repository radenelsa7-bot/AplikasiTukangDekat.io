<?php

namespace App\Http\Controllers\Api;

use App\Models\WilayahKecamatan;
use App\Models\WilayahKota;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreWilayahKecamatanRequest;
use App\Http\Requests\UpdateWilayahKecamatanRequest;
use App\Traits\ApiResponse;

/**
 * @OA\Tag(
 *     name="Districts (Admin)",
 *     description="District data management - Admin only"
 * )
 */
class DistrictController extends Controller
{
    use ApiResponse;

    /**
     * Display districts by city.
     * 
     * @OA\Get(
     *     path="/api/districts",
     *     tags={"Districts (Admin)"},
     *     summary="Get districts by city",
     *     @OA\Parameter(
     *         name="city_id",
     *         in="query",
     *         description="Filter by city ID",
     *         required=false,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Parameter(
     *         name="search",
     *         in="query",
     *         description="Search district by name",
     *         required=false,
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(response=200, description="Success"),
     * )
     */
    public function index()
    {
        $cityId = request('city_id');
        $search = request('search');
        
        $query = WilayahKecamatan::query();
        
        if ($cityId) {
            $query->where('kota_id', $cityId);
        }
        
        if ($search) {
            $query->where('name', 'like', "%$search%");
        }
        
        $districts = $query->orderBy('name')->get();
        
        return $this->success($districts, 'Districts retrieved successfully');
    }

    /**
     * Store a newly created district in storage.
     * Admin only.
     * 
     * @OA\Post(
     *     path="/api/admin/districts",
     *     tags={"Districts (Admin)"},
     *     summary="Create new district",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"city_id", "name"},
     *             @OA\Property(property="city_id", type="integer", example=1),
     *             @OA\Property(property="name", type="string", example="Pusat")
     *         )
     *     ),
     *     @OA\Response(response=201, description="District created"),
     *     @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function store(StoreWilayahKecamatanRequest $request)
    {
        try {
            // Verify city exists
            $city = WilayahKota::find($request->city_id);
            if (!$city) {
                return $this->notFound('City not found');
            }

            $district = WilayahKecamatan::create($request->validated());
            return $this->success($district, 'District created successfully', 201);
        } catch (\Exception $e) {
            return $this->error('Failed to create district: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Display the specified district.
     * 
     * @OA\Get(
     *     path="/api/districts/{id}",
     *     tags={"Districts (Admin)"},
     *     summary="Get district by ID",
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(response=200, description="Success"),
     *     @OA\Response(response=404, description="Not found"),
     * )
     */
    public function show($id)
    {
        $district = WilayahKecamatan::with('kota')->find($id);
        
        if (!$district) {
            return $this->notFound('District not found');
        }
        
        return $this->success($district, 'District retrieved successfully');
    }

    /**
     * Update the specified district in storage.
     * Admin only.
     * 
     * @OA\Put(
     *     path="/api/admin/districts/{id}",
     *     tags={"Districts (Admin)"},
     *     summary="Update district",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name"},
     *             @OA\Property(property="name", type="string", example="Pusat Jaya")
     *         )
     *     ),
     *     @OA\Response(response=200, description="Updated"),
     *     @OA\Response(response=404, description="Not found"),
     * )
     */
    public function update(UpdateWilayahKecamatanRequest $request, $id)
    {
        $district = WilayahKecamatan::find($id);
        
        if (!$district) {
            return $this->notFound('District not found');
        }

        try {
            $district->update($request->validated());
            return $this->success($district, 'District updated successfully');
        } catch (\Exception $e) {
            return $this->error('Failed to update district: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Remove the specified district from storage.
     * Admin only.
     * 
     * @OA\Delete(
     *     path="/api/admin/districts/{id}",
     *     tags={"Districts (Admin)"},
     *     summary="Delete district",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(response=200, description="Deleted"),
     *     @OA\Response(response=404, description="Not found"),
     * )
     */
    public function destroy($id)
    {
        $district = WilayahKecamatan::find($id);
        
        if (!$district) {
            return $this->notFound('District not found');
        }

        try {
            // Check if there are providers using this district
            $providerCount = \App\Models\User::where('role', 'PROVIDER')
                ->where('district_id', $id)
                ->count();

            if ($providerCount > 0) {
                return $this->error(
                    "Cannot delete district with $providerCount active providers. Relocate providers first.",
                    409
                );
            }

            $district->delete();
            return $this->success(null, 'District deleted successfully');
        } catch (\Exception $e) {
            return $this->error('Failed to delete district: ' . $e->getMessage(), 500);
        }
    }
}
