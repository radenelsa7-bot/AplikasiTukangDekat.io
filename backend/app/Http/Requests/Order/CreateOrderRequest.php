<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class CreateOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'provider_id' => 'required|exists:users,id',
            'provider_service_id' => 'nullable|exists:provider_services,id',
            'category_id' => 'required|exists:service_categories,id',
            'schedule_at' => 'required|date_format:Y-m-d H:i:s',
            'address' => 'required|string',
            'notes' => 'nullable|string',
            'estimated_price' => 'required|integer|min:1',
        ];
    }
}
