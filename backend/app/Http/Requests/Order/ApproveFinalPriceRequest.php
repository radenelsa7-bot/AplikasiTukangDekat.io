<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class ApproveFinalPriceRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        return $user && $user->role === 'CUSTOMER';
    }

    public function rules(): array
    {
        return [
            'action' => 'required|in:approve,reject',
            'reason' => 'nullable|string|max:500',
        ];
    }
}
