<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class RespondOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'action' => 'required|in:accept,reject',
        ];
    }
}
