<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PayoutProviderResponse extends Model
{
    protected $table = 'payout_provider_responses';

    protected $fillable = [
        'provider',
        'transaction_reference',
        'path',
        'request_body',
        'response_body',
        'status_code',
    ];

    protected $casts = [
        'request_body' => 'array',
        'response_body' => 'array',
    ];
}
