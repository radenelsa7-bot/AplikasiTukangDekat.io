<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureAdminRole
{
    public function handle(Request $request, Closure $next)
    {
        if ($request->user()?->role !== 'ADMIN') {
            return response()->json([
                'success' => false,
                'message' => 'Only administrators can access this resource.',
                'error_code' => 'FORBIDDEN',
                'status_code' => 403,
            ], 403);
        }

        return $next($request);
    }
}
