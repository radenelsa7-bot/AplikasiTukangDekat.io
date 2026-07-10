<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('final_price_approvals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->onDelete('cascade');

            // harga akhir yang diajukan provider
            $table->unsignedInteger('proposed_final_price');

            // persetujuan customer
            $table->enum('approval_status', ['PENDING', 'APPROVED', 'REJECTED'])->default('PENDING');
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();

            $table->index('order_id');
            $table->index('approval_status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('final_price_approvals');
    }
};
