<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Models\ProviderProfile;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Laravel\Sanctum\PersonalAccessToken;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\QueryException;

class AuthController extends Controller
{
    use ApiResponse;

    /**
     * Register user baru
     */
    public function register(RegisterRequest $request)
    {
        try {
            $validated = $request->validated();

            // Wrap DB create in retry in case of transient connection/DNS failures
            $user = $this->dbAttempt(function () use ($validated) {
                return User::create([
                    'name' => $validated['name'],
                    'email' => $validated['email'],
                    'phone' => $validated['phone'],
                    'password' => Hash::make($validated['password']),
                    'role' => $validated['role'],
                    'status' => 'ACTIVE',
                ]);
            });

            if ($validated['role'] === 'PROVIDER') {
                $this->dbAttempt(function () use ($user) {
                    ProviderProfile::create([
                        'user_id' => $user->id,
                        'is_verified' => false,
                    ]);
                });
            }

            return $this->success([
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'full_name' => $user->full_name,
                    'phone_number' => $user->phone_number,
                    'profile_photo_path' => $user->profile_photo_path,
                ],
            ], 'User registered successfully', 201);
        } catch (ValidationException $e) {
            return $this->validationError($e->errors());
        } catch (\Throwable $e) {
            Log::error('Register error: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return $this->internalServerError('Failed to register user');
        }
    }

    /**
     * Login user
     */
    public function login(LoginRequest $request)
    {
        try {
            $validated = $request->validated();

            $user = $this->dbAttempt(function () use ($validated) {
                return User::where('email', $validated['email'])->first();
            });

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
                    'full_name' => $user->full_name,
                    'phone_number' => $user->phone_number,
                    'profile_photo_path' => $user->profile_photo_path,
                ],
            ], 'Login successful', 200);
        } catch (\Throwable $e) {
            Log::error('Login error: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return $this->internalServerError('Failed to login user');
        }
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
                'id' => $user?->id,
                'name' => $user?->name,
                'email' => $user?->email,
                'role' => $user?->role,
            ],
        ], 'Session login successful', 200);
    }

    /**
     * Logout user
     */
    public function logout(Request $request)
    {
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
        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return $this->success(null, 'Session logout successful', 200);
    }

    /**
     * Helper to retry DB operations for transient failures (DNS/connection).
     * Accepts a callable that performs DB work and returns its result.
     */
    private function dbAttempt(callable $fn, int $retries = 3, int $delayMicros = 500000)
    {
        $lastException = null;
        for ($i = 0; $i < $retries; $i++) {
            try {
                return $fn();
            } catch (QueryException $e) {
                $lastException = $e;
                Log::warning('DB attempt failed, retrying: ' . $e->getMessage(), ['attempt' => $i + 1]);
                usleep($delayMicros);
                continue;
            } catch (\PDOException $e) {
                $lastException = $e;
                Log::warning('PDO attempt failed, retrying: ' . $e->getMessage(), ['attempt' => $i + 1]);
                usleep($delayMicros);
                continue;
            }
        }

        // If we reach here, rethrow the last exception so it gets logged by caller
        if ($lastException instanceof \Throwable) {
            throw $lastException;
        }

        return null;
    }
}
