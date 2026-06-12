<?php

namespace App\Http\Requests\Integration;

use Illuminate\Foundation\Http\FormRequest;

class DispatchN8nEventRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'event_name' => 'required|string',
            'payload' => 'sometimes|array',
            'channel' => 'sometimes|string|in:WA,EMAIL',
        ];
    }
}
