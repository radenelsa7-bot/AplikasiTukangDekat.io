<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CheckRole
{
  public function handle(Request $request, Closure $next, string $mode)
  {
    $user = Auth::user();

    if (!$user) {
      return response()->json(['message' => 'unauthenticated'], 401);
    }

    $userRole = strtoupper((string) ($user->role ?? ''));

    if ($mode === 'admin') {
      // ADMIN role includes all treasurer capabilities
      if ($userRole !== 'ADMIN') {
        return response()->json(['message' => 'forbidden'], 403);
      }
      return $next($request);
    }

    if ($mode === 'customer') {
      if ($userRole !== 'CUSTOMER') {
        return response()->json(['message' => 'forbidden'], 403);
      }
      return $next($request);
    }

    if ($mode === 'provider') {
      if ($userRole !== 'PROVIDER') {
        return response()->json(['message' => 'forbidden'], 403);
      }
      return $next($request);
    }

    if ($mode === 'treasurer') {
      // ADMIN role can also access treasurer endpoints
      if ($userRole !== 'ADMIN' && $userRole !== 'TREASURER') {
        return response()->json(['message' => 'forbidden'], 403);
      }
      return $next($request);
    }

    if ($mode === 'readonly') {
      if ($userRole === 'ADMIN' || $userRole === 'TREASURER') {
        return $next($request);
      }
      return response()->json(['message' => 'forbidden'], 403);
    }

    if ($mode === 'write') {
      if ($userRole === 'ADMIN') {
        return $next($request);
      }
      return response()->json(['message' => 'forbidden'], 403);
    }

    return response()->json(['message' => 'invalid role check configuration'], 500);
  }
}
