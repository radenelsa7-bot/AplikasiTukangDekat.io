<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EnsureRole
{
    /**
     * Handle an incoming request.
     * Usage in routes: ->middleware(\App\Http\Middleware\EnsureRole::class . ':ADMIN')
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @param  string  $role
     * @return mixed
     */
    public function handle(Request $request, Closure $next, string $role)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $expected = strtoupper($role);
        $userRole = strtoupper((string) ($user->role ?? ''));

        if ($userRole !== $expected) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return $next($request);
    }
}
