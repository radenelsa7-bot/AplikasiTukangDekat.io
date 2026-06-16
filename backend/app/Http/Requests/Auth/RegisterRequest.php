<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Public endpoint
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:100',
            'email' => 'required|string|email|unique:users',
            'phone' => 'required|string|max:30',
            'password' => [
                'required',
                'string',
                'min:8',
                'regex:/[A-Z]/',      // uppercase
                'regex:/[0-9]/',      // number
                'regex:/[@$!%*?&]/',  // special char
                'confirmed',
            ],
            'role' => 'required|in:CUSTOMER,PROVIDER',
        ];
    }

    public function messages(): array
    {
        return [
            'password.min' => 'Password must be at least 8 characters long.',
            'password.regex' => 'Password must contain uppercase letter, number, and special character (@$!%*?&).',
            'password.confirmed' => 'Password confirmation does not match.',
        ];
    }

    /**
     * Customize failed validation to return JSON in our API format
     */
    protected function failedValidation(Validator $validator)
    {
        $response = response()->json([
            'success' => false,
            'message' => 'Validation failed',
            'error_code' => 'VALIDATION_ERROR',
            'status_code' => 422,
            'errors' => $validator->errors(),
        ], 422);

        throw new HttpResponseException($response);
    }
}
}
