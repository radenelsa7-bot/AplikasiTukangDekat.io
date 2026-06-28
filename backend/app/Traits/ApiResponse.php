<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    /**
     * Return a success JSON response
     */
    protected function success($data = null, string $message = 'Success', int $statusCode = 200): JsonResponse
    {
        $response = [
            'success' => true,
            'message' => $message,
        ];

        if ($data !== null) {
            $response['data'] = $data;
        }

        return response()->json($response, $statusCode);
    }

    /**
     * Return a paginated JSON response
     */
    protected function paginated($data, string $message = 'Success'): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data->items(),
            'pagination' => [
                'total' => $data->total(),
                'per_page' => $data->perPage(),
                'current_page' => $data->currentPage(),
                'last_page' => $data->lastPage(),
                'from' => $data->firstItem(),
                'to' => $data->lastItem(),
            ],
        ], 200);
    }

    /**
     * Return an error JSON response
     */
    protected function error(string $message, int $statusCode = 400, ?string $errorCode = null, $details = null): JsonResponse
    {
        $response = [
            'success' => false,
            'message' => $message,
            'status_code' => $statusCode,
        ];

        if ($errorCode) {
            $response['error_code'] = $errorCode;
        }

        if ($details) {
            $response['details'] = $details;
        }

        return response()->json($response, $statusCode);
    }

    /**
     * Return a validation error response
     */
    protected function validationError($errors, string $message = 'Validation failed'): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'error_code' => 'VALIDATION_ERROR',
            'status_code' => 422,
            'errors' => $errors,
        ], 422);
    }

    /**
     * Return an unauthorized response
     */
    protected function unauthorized(string $message = 'Unauthorized'): JsonResponse
    {
        return $this->error($message, 401, 'UNAUTHORIZED');
    }

    /**
     * Return a forbidden response
     */
    protected function forbidden(string $message = 'Forbidden'): JsonResponse
    {
        return $this->error($message, 403, 'FORBIDDEN');
    }

    /**
     * Return a not found response
     */
    protected function notFound(string $message = 'Resource not found'): JsonResponse
    {
        return $this->error($message, 404, 'NOT_FOUND');
    }

    /**
     * Return a conflict response (usually for state/business logic errors)
     */
    protected function conflict(string $message, ?string $errorCode = null): JsonResponse
    {
        return $this->error($message, 409, $errorCode ?? 'CONFLICT');
    }

    /**
     * Return a too many requests response (rate limit)
     */
    protected function tooManyRequests(string $message = 'Too many requests'): JsonResponse
    {
        return $this->error($message, 429, 'RATE_LIMIT');
    }

    /**
     * Return an internal server error response
     */
    protected function internalServerError(string $message = 'Internal server error', ?string $errorCode = null): JsonResponse
    {
        return $this->error($message, 500, $errorCode ?? 'INTERNAL_SERVER_ERROR');
    }
}
