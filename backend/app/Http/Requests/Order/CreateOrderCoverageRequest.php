<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class CreateOrderCoverageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'CUSTOMER';
    }

    public function rules(): array
    {
        return [
            'kota_id' => 'required|integer|exists:wilayah_kota,id',
            'kecamatan_id' => 'required|integer|exists:wilayah_kecamatan,id',
        ];
    }
}
