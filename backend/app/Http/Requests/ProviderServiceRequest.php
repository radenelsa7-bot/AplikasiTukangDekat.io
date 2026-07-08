<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class ProviderServiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        if ($this->isMethod('patch') || $this->isMethod('put')) {
            return [
                'category_id' => 'sometimes|exists:service_categories,id',
                'name' => 'sometimes|string|max:120',
                'description' => 'sometimes|nullable|string|max:1000',
                'base_price' => 'sometimes|integer|min:0',
                'price_unit' => 'sometimes|nullable|string|max:30',
                'is_active' => 'sometimes|boolean',
            ];
        }

        return [
            'category_id' => 'required|exists:service_categories,id',
            'name' => 'required|string|max:120',
            'description' => 'nullable|string|max:1000',
            'base_price' => 'required|integer|min:0',
            'price_unit' => 'nullable|string|max:30',
            'is_active' => 'sometimes|boolean',
        ];
    }

    public function messages(): array
    {
        return [
            'category_id.required' => 'The category id is required.',
            'category_id.exists' => 'The selected category does not exist.',
            'name.required' => 'The service name is required.',
            'name.max' => 'The service name may not be greater than 120 characters.',
            'base_price.required' => 'The base price is required.',
            'base_price.integer' => 'The base price must be an integer.',
            'base_price.min' => 'The base price must be at least 0.',
            'price_unit.max' => 'The price unit may not be greater than 30 characters.',
            'is_active.boolean' => 'The is active field must be true or false.',
        ];
    }

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
