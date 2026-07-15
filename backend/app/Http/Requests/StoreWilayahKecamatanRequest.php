<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreWilayahKecamatanRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Only admin can create districts
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
            'city_id' => ['required', 'integer', 'exists:wilayah_kota,id'],
            'name' => ['required', 'string', 'max:120'],
        ];
    }

    public function messages(): array
    {
        return [
            'city_id.required' => 'City is required',
            'city_id.exists' => 'Selected city does not exist',
            'name.required' => 'District name is required',
            'name.max' => 'District name must not exceed 120 characters',
        ];
    }
}
