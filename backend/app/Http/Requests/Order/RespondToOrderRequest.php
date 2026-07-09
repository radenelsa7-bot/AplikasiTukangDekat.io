<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class RespondToOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        // Sanctum sometimes resolves the authenticated user late in the pipeline.
        // Fallback to Auth facade via $this->user() which is backed by the request.
        if (!$user) {
            return false;
        }

        $role = strtoupper((string) ($user->role ?? ''));

        return $role === 'PROVIDER';
    }


    public function rules(): array
    {
        return [
            'action' => 'required|in:accept,reject',
        ];
    }

    public function messages(): array
    {
        return [
            'action.required' => 'Action is required (accept or reject).',
            'action.in' => 'Action must be either accept or reject.',
        ];
    }
}

