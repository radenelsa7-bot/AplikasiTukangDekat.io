<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateVerificationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'ADMIN';
        return true;
    }

    public function rules(): array
    {
        return [
            'is_verified' => 'required|boolean',
        ];
    }

    public function messages(): array
    {
        return [
            'is_verified.required' => 'Verification status is required.',
            'is_verified.boolean' => 'Verification status must be true or false.',
        ];
    }
}
