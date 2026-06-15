<?php

namespace App\Http\Requests\Review;

use Illuminate\Foundation\Http\FormRequest;

class CreateReviewRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'CUSTOMER';
        return true;
    }

    public function rules(): array
    {
        return [
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ];
    }

    public function messages(): array
    {
        return [
            'rating.required' => 'Rating is required.',
            'rating.integer' => 'Rating must be a whole number.',
            'rating.min' => 'Rating must be at least 1 star.',
            'rating.max' => 'Rating cannot exceed 5 stars.',
            'comment.max' => 'Comment cannot exceed 1000 characters.',
            'rating' => 'required|integer|between:1,5',
            'comment' => 'nullable|string',
        ];
    }
}
