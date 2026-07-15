<?php

namespace App\Http\Controllers\Api;

use App\Models\WilayahKota;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreWilayahKotaRequest;
use App\Http\Requests\UpdateWilayahKotaRequest;
use App\Traits\ApiResponse;

/**
 * @OA\Tag(
 *     name="Cities (Admin)",
 *     description="City data management - Admin only"
 * )
 */
class CityController extends Controller
{
    use ApiResponse;

    /**
     * Display a listing of cities.
     * 
     * @OA\Get(
     *     path="/api/cities",
     *     tags={"Cities (Admin)"},
     *     summary="Get all cities",
     *     @OA\Parameter(
     *         name="search",
     *         in="query",
     *         description="Search city by name",
     *         required=false,
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(response=200, description="Success"),
     * )
     */
    public function index()
    {
        $search = request('search');
        
        $query = WilayahKota::query();
        
        if ($search) {
            $query->where('name', 'like', "%$search%");
        }
        
        $cities = $query->orderBy('name')->get();
        
        return $this->success($cities, 'Cities retrieved successfully');
    }

    /**
     * Store a newly created city in storage.
     * Admin only.
     * 
     * @OA\Post(
     *     path="/api/admin/cities",
     *     tags={"Cities (Admin)"},
     *     summary="Create new city",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"name"},
     *             @OA\Property(property="name", type="string", example="Jakarta")
     *         )
     *     ),
     *     @OA\Response(response=201, description="City created"),
     *     @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function store(StoreWilayahKotaRequest $request)
    {
        try {
            $city = WilayahKota::create($request->validated());
            return $this->success($city, 'City created successfully', 201);
        } catch (\Exception $e) {
            return $this->error('Failed to create city: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Display the specified city.
     * 
     * @OA\Get(
     *     path="/api/cities/{id}",
     *     tags={"Cities (Admin)"},
     *     summary="Get city by ID",
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
        $city = WilayahKota::with('kecamatan')->find($id);
        
        if (!$city) {
            return $this->notFound('City not found');
        }
        
        return $this->success($city, 'City retrieved successfully');
    }

    /**
     * Update the specified city in storage.
     * Admin only.
     * 
     * @OA\Put(
     *     path="/api/admin/cities/{id}",
     *     tags={"Cities (Admin)"},
     *     summary="Update city",
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
     *             @OA\Property(property="name", type="string", example="Jakarta Pusat")
     *         )
     *     ),
     *     @OA\Response(response=200, description="Updated"),
     *     @OA\Response(response=404, description="Not found"),
     * )
     */
    public function update(UpdateWilayahKotaRequest $request, $id)
    {
        $city = WilayahKota::find($id);
        
        if (!$city) {
            return $this->notFound('City not found');
        }

        try {
            $city->update($request->validated());
            return $this->success($city, 'City updated successfully');
        } catch (\Exception $e) {
            return $this->error('Failed to update city: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Remove the specified city from storage.
     * Admin only. Districts will be cascade deleted.
     * 
     * @OA\Delete(
     *     path="/api/admin/cities/{id}",
     *     tags={"Cities (Admin)"},
     *     summary="Delete city",
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
        $city = WilayahKota::find($id);
        
        if (!$city) {
            return $this->notFound('City not found');
        }

        try {
            // Check if there are providers using this city
            $providerCount = \App\Models\User::where('role', 'PROVIDER')
                ->where('city_id', $id)
                ->count();

            if ($providerCount > 0) {
                return $this->error(
                    "Cannot delete city with $providerCount active providers. Relocate providers first.",
                    409
                );
            }

            $city->delete();
            return $this->success(null, 'City deleted successfully');
        } catch (\Exception $e) {
            return $this->error('Failed to delete city: ' . $e->getMessage(), 500);
        }
    }
}
