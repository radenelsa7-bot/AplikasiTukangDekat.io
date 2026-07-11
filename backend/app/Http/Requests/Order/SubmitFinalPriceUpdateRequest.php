<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class SubmitFinalPriceUpdateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'PROVIDER';
    }

    public function rules(): array
    {
        return [
            'proposed_final_price' => 'required|integer|min:1|max:100000000',
        ];
    }

    public function messages(): array
    {
        return [
            'proposed_final_price.required' => 'Proposed final price is required.',
            'proposed_final_price.integer' => 'Proposed final price must be an integer.',
            'proposed_final_price.min' => 'Proposed final price must be at least 1.',
            'proposed_final_price.max' => 'Proposed final price cannot exceed 100,000,000.',
        ];
    }
}
