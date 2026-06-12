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

    if ($mode === 'admin') {
      if ($user->role !== 'ADMIN') {
        return response()->json(['message' => 'forbidden'], 403);
      }
      return $next($request);
    }

    if ($mode === 'readonly') {
      if ($user->role === 'TREASURER' || $user->role === 'ADMIN') {
        return $next($request);
      }
      return response()->json(['message' => 'forbidden'], 403);
    }

    if ($mode === 'write') {
      if ($user->role === 'ADMIN') {
        return $next($request);
      }

      if ($user->role === 'TREASURER') {
        return response()->json(['message' => 'forbidden'], 403);
      }

      return $next($request);
    }

    return response()->json(['message' => 'invalid role check configuration'], 500);
  }
}
