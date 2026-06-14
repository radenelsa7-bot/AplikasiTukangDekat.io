<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:100',
            'email' => 'required|string|email|unique:users',
            'phone' => 'required|string|max:30',
            'password' => 'required|string|min:6|confirmed',
            'role' => 'required|in:CUSTOMER,PROVIDER',
        ];
    }
}
