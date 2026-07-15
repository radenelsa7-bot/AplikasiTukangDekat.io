<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreWilayahKotaRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Only admin can create cities
        return $this->user() && $this->user()->role === 'ADMIN';
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array|string>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:120', 'unique:wilayah_kota,name'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'City name is required',
            'name.unique' => 'City name must be unique',
            'name.max' => 'City name must not exceed 120 characters',
        ];
    }
}
