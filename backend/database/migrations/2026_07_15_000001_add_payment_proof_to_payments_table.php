<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->string('payment_proof_path')->nullable()->after('external_payment_id');
            $table->dateTime('payment_proof_uploaded_at')->nullable()->after('payment_proof_path');
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn(['payment_proof_path', 'payment_proof_uploaded_at']);
        });
    }
};
