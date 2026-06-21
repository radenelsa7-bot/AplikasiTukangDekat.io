<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('chatbot_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('request_id')->unique()->comment('UUID untuk tracking API call');
            $table->longText('user_message')->comment('Pesan dari user');
            $table->longText('assistant_message')->nullable()->comment('Respons dari Gemini');
            $table->json('order_context')->nullable()->comment('Konteks pesanan yang dikirim ke AI');
            $table->integer('response_time_ms')->comment('Waktu respons dalam milidetik');
            $table->enum('status', ['success', 'error', 'retry', 'rate_limited'])->comment('Status request');
            $table->string('error_code')->nullable()->comment('Kode error jika ada (GEMINI_API_ERROR, timeout, dll)');
            $table->longText('error_message')->nullable()->comment('Pesan detail error');
            $table->integer('retry_count')->default(0)->comment('Jumlah retry yang dilakukan');
            $table->integer('tokens_used')->nullable()->comment('Jumlah tokens yang digunakan di Gemini');
            $table->decimal('api_cost_usd', 8, 6)->nullable()->comment('Estimasi biaya API call');
            $table->json('metadata')->nullable()->comment('Data tambahan (user agent, IP, dll)');
            $table->timestamps();

            // Indexes untuk query yang efisien
            $table->index('user_id');
            $table->index('status');
            $table->index('error_code');
            $table->index('created_at');
            $table->index(['user_id', 'created_at']);
            $table->index(['status', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('chatbot_logs');
    }
};
