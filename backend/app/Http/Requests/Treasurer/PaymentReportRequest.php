<?php

namespace App\Http\Requests\Treasurer;

use Illuminate\Foundation\Http\FormRequest;

class PaymentReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'start_date' => 'nullable|date_format:Y-m-d',
            'end_date' => 'nullable|date_format:Y-m-d|after_or_equal:start_date',
            'status' => 'nullable|in:UNPAID,PENDING,PAID,FAILED,EXPIRED',
            'payment_type' => 'nullable|in:DP,FINAL',
            'order_id' => 'nullable|integer|exists:orders,id',
            'provider_id' => 'nullable|integer|exists:users,id',
            'per_page' => 'nullable|integer|min:1|max:100',
        ];
    }
}
