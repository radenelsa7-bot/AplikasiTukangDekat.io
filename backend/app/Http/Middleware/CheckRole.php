<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CheckRole
{
  /**
   * Handle an incoming request.
   *
   * @param  \Illuminate\Http\Request  $request
   * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
   * @param  string  $mode
   * @return mixed
   */
  public function handle(Request $request, Closure $next, string $mode)
  {
    $user = Auth::user();

    if (!$user) {
      return response()->json(['message' => 'unauthenticated'], 401);
    }

    $normalizedRole = strtoupper($user->role);

    if ($mode === 'admin') {
      if ($normalizedRole !== 'ADMIN') {
        return response()->json(['message' => 'forbidden'], 403);
      }
      return $next($request);
    }

    if ($mode === 'customer') {
      if ($normalizedRole !== 'CUSTOMER') {
        return response()->json(['message' => 'forbidden'], 403);
      }
      return $next($request);
    }

    if ($mode === 'provider') {
      if ($normalizedRole !== 'PROVIDER') {
        return response()->json(['message' => 'forbidden'], 403);
      }
      return $next($request);
    }

    if ($mode === 'treasurer') {
      if (!in_array($normalizedRole, ['TREASURER', 'ADMIN'], true)) {
        return response()->json(['message' => 'forbidden'], 403);
      }
      return $next($request);
    }

    if ($mode === 'readonly') {
      if (in_array($normalizedRole, ['TREASURER', 'ADMIN'], true)) {
        return $next($request);
      }
      return response()->json(['message' => 'forbidden'], 403);
    }

    if ($mode === 'write') {
      if ($normalizedRole === 'ADMIN') {
        return $next($request);
      }

      if ($normalizedRole === 'TREASURER') {
        return response()->json(['message' => 'forbidden'], 403);
      }

      return $next($request);
    }

    return response()->json(['message' => 'invalid role check configuration'], 500);
  }
}
