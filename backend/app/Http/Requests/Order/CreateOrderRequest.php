<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CreateOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'CUSTOMER';
    }

    public function rules(): array
    {
        return [
            'provider_id' => [
                'required',
                'integer',
                Rule::exists('users', 'id')->where('role', 'PROVIDER'),
            ],
            'provider_service_id' => 'nullable|exists:provider_services,id',
            'category_id' => 'required|exists:service_categories,id',
            'schedule_at' => 'required|date_format:Y-m-d H:i:s|after:now',
            'address' => 'required|string|max:500',
            'notes' => 'nullable|string|max:1000',
            'estimated_price' => 'required|integer|min:1|max:100000000',
        ];
    }

    public function messages(): array
    {
        return [
            'provider_id.required' => 'Provider is required.',
            'provider_id.exists' => 'The selected provider does not exist or is not a valid provider.',
            'category_id.required' => 'Service category is required.',
            'category_id.exists' => 'The selected service category does not exist.',
            'schedule_at.required' => 'Schedule time is required.',
            'schedule_at.date_format' => 'Schedule time must be in format Y-m-d H:i:s.',
            'schedule_at.after' => 'Schedule time must be in the future.',
            'address.required' => 'Address is required.',
            'estimated_price.required' => 'Estimated price is required.',
            'estimated_price.min' => 'Estimated price must be at least 1.',
            'estimated_price.max' => 'Estimated price cannot exceed 100,000,000.',
        ];
    }
}
