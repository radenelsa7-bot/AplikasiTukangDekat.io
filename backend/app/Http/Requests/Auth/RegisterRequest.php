<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $rules = [
            'name' => 'required|string|max:100',
            'email' => 'required|string|email|unique:users',
            'phone' => 'required|string|max:30',
            'password' => [
                'required',
                'string',
                'min:8',
                'regex:/[A-Z]/',
                'regex:/[0-9]/',
                'regex:/[@$!%*?&]/',
                'confirmed',
            ],
            'role' => 'required|in:CUSTOMER,PROVIDER',
        ];

        // Additional fields required for PROVIDER registration
        if ($this->input('role') === 'PROVIDER') {
            $rules['category_id'] = 'required|integer|exists:service_categories,id';
            $rules['business_name'] = 'required|string|max:150';
            $rules['service_name'] = 'nullable|string|max:100';
            $rules['base_price'] = 'nullable|integer|min:0';
            $rules['city_id'] = 'required|integer|exists:wilayah_kota,id';
            $rules['district_id'] = [
                'required',
                'integer',
                Rule::exists('wilayah_kecamatan', 'id')->where(function ($query) {
                    return $query->where('kota_id', $this->input('city_id'));
                }),
            ];
        }

        return $rules;
    }

    public function messages(): array
    {
        return [
            'password.min' => 'Password must be at least 8 characters long.',
            'password.regex' => 'Password must contain uppercase letter, number, and special character (@$!%*?&).',
            'password.confirmed' => 'Password confirmation does not match.',
            'city_id.required' => 'City is required for provider registration.',
            'city_id.exists' => 'Selected city does not exist.',
            'district_id.required' => 'District is required for provider registration.',
            'district_id.exists' => 'Selected district does not exist or does not belong to the selected city.',
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
