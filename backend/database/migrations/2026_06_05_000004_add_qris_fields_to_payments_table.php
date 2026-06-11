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
        Schema::table('payments', function (Blueprint $table) {
            if (!Schema::hasColumn('payments', 'qris_code')) {
                $table->string('qris_code')->nullable()->after('external_payment_id');
            }
            if (!Schema::hasColumn('payments', 'qris_image')) {
                $table->text('qris_image')->nullable()->after('qris_code');
            }
            if (!Schema::hasColumn('payments', 'checkout_url')) {
                $table->string('checkout_url')->nullable()->after('qris_image');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn(['qris_code', 'qris_image', 'checkout_url']);
        });
    }
};
