<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatMessage extends Model
{
    protected $table = 'chat_messages';

    protected $fillable = [
        'user_id',
        'order_id',
        'role', // 'user' or 'assistant' or 'system'
        'message',
        'raw_response',
    ];

    protected $casts = [
        'raw_response' => 'array',
    ];
}
