<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class BookingRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'name' => 'required|string|max:191',
            'phone' => 'required|string|max:32',
            'city' => 'nullable|string|max:191',
            'service' => 'required|string|max:191',
            'schedule' => 'nullable|date',
            'notes' => 'nullable|string',
        ];
    }
}
