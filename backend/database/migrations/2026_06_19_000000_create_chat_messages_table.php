<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_messages', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('user_id')->index();
            $table->unsignedBigInteger('order_id')->nullable()->index();
            $table->string('role', 32);
            $table->text('message');
            $table->json('raw_response')->nullable();
            $table->timestamps();

            // Foreign keys are optional depending on project conventions
            // $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            // $table->foreign('order_id')->references('id')->on('orders')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_messages');
    }
};