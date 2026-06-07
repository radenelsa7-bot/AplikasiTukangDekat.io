<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ProviderProfile;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\JsonResponse;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\LoginRequest;

class AuthController extends Controller
{
    use ApiResponse;
    /**
     * Register user baru
     */
    public function register(RegisterRequest $request)
    {
        $validated = $request->validated();

        try {
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'],
                'password' => Hash::make($validated['password']),
                'role' => $validated['role'],
                'status' => 'ACTIVE',
            ]);

            // Jika provider, buat provider profile
            if ($validated['role'] === 'PROVIDER') {
                ProviderProfile::create([
                    'user_id' => $user->id,
                    'is_verified' => false,
                ]);
            }

            return $this->success([
                'user_id' => $user->id,
                'role' => $user->role,
            ], 'User registered successfully', 201);
        } catch (\Throwable $e) {
            return $this->internalServerError('Failed to register user');
        }
    }

    /**
     * Login user
     */
    public function login(LoginRequest $request)
    {
        $validated = $request->validated();

        $user = User::query()->where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return $this->unauthorized('The provided credentials are incorrect.');
        }

        if ($user->status !== 'ACTIVE') {
            return $this->forbidden('Your account is not active.');
        }

        $token = $user->createToken('api-token')->plainTextToken;

        return $this->success([
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ],
        ], 'Login successful', 200);
    }

    /**
     * Session-based login for Sanctum SPA (web)
     */
    public function sessionLogin(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();

        if (!Auth::attempt(['email' => $validated['email'], 'password' => $validated['password']], $request->boolean('remember'))) {
            return $this->unauthorized('Invalid credentials');
        }

        $request->session()->regenerate();

        $user = $request->user();

        return $this->success([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ],
        ], 'Session login successful', 200);
    }

    /**
     * Logout user
     */
    public function logout(Request $request)
    {
        // Revoke current token
        $token = $request->user()?->currentAccessToken();
        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        }

        return $this->success(null, 'Logged out successfully', 200);
    }

    /**
     * Session-based logout for Sanctum SPA (web)
     */
    public function sessionLogout(Request $request): JsonResponse
    {
        Auth::guard()->logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return $this->success(null, 'Session logout successful', 200);
    }
}
