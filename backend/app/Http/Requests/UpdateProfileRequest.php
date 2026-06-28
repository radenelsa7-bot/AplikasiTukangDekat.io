<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class UpdateProfileRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'full_name' => 'nullable|string|max:255',
      'phone_number' => ['nullable', 'string', 'regex:/^[0-9]+$/', 'min:10', 'max:15'],
      'profile_photo' => 'nullable|file|mimes:jpeg,png,jpg|max:2048',
    ];
  }

  public function messages(): array
  {
    return [
      'phone_number.regex' => 'The phone number must contain only digits.',
      'profile_photo.max' => 'The profile photo may not be greater than 2MB.',
      'profile_photo.mimes' => 'The profile photo must be a file of type: jpeg, png, jpg.',
    ];
  }

  protected function failedValidation(Validator $validator)
  {
    $response = response()->json([
      'success' => false,
      'message' => 'Validation failed',
      'error_code' => 'VALIDATION_ERROR',
      'status_code' => 422,
      'errors' => $validator->errors(),
    ], 422);

    throw new HttpResponseException($response);
  }
}
