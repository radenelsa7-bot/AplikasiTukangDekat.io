<?php

namespace App\Http\Responses;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    protected function successResponse(array|null $data = null, string $message = 'ok', int $status = 200, array $meta = []): JsonResponse
    {
        $payload = ['message' => $message];

        if ($data !== null) {
            $payload['data'] = $data;
        }

        if (!empty($meta)) {
            $payload['meta'] = $meta;
        }

        return response()->json($payload, $status);
    }

    protected function createdResponse(array|null $data = null, string $message = 'created', array $meta = []): JsonResponse
    {
        return $this->successResponse($data, $message, 201, $meta);
    }

    protected function errorResponse(string $message, int $status = 400, array $errors = []): JsonResponse
    {
        $payload = ['message' => $message];

        if (!empty($errors)) {
            $payload['errors'] = $errors;
        }

        return response()->json($payload, $status);
    }

    protected function notFoundResponse(string $message = 'not found'): JsonResponse
    {
        return $this->errorResponse($message, 404);
    }

    protected function forbiddenResponse(string $message = 'forbidden'): JsonResponse
    {
        return $this->errorResponse($message, 403);
    }

    protected function unauthorizedResponse(string $message = 'unauthorized'): JsonResponse
    {
        return $this->errorResponse($message, 401);
    }
}
