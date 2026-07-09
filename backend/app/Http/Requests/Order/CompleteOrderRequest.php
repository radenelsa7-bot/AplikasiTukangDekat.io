<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class CompleteOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'PROVIDER';
    }

    public function rules(): array
    {
        return [
            'final_price' => 'required|integer|min:1|max:100000000',
            'initial_condition_photos' => 'nullable|array|max:5',
            'initial_condition_photos.*' => 'file|mimes:jpeg,jpg,png|max:5120',
            'final_condition_photos' => 'nullable|array|max:5',
            'final_condition_photos.*' => 'file|mimes:jpeg,jpg,png|max:5120',
            'receipt_photos' => 'nullable|array|max:5',
            'receipt_photos.*' => 'file|mimes:jpeg,jpg,png|max:5120',
        ];
    }

    public function messages(): array
    {
        return [
            'final_price.required' => 'Final price is required.',
            'final_price.integer' => 'Final price must be a valid amount.',
            'final_price.min' => 'Final price must be at least 1.',
            'final_price.max' => 'Final price cannot exceed 100,000,000.',
            'final_price' => 'required|integer|min:1',
        ];
    }
}
