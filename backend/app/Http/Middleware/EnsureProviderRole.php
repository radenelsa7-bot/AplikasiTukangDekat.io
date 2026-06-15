<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureProviderRole
{
    public function handle(Request $request, Closure $next)
    {
        if ($request->user()?->role !== 'PROVIDER') {
            return response()->json([
                'success' => false,
                'message' => 'Only providers can access this resource.',
                'error_code' => 'FORBIDDEN',
                'status_code' => 403,
            ], 403);
        }

        return $next($request);
    }
}
