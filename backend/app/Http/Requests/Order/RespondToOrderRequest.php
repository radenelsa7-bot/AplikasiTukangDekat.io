<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class RespondToOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'PROVIDER';
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
