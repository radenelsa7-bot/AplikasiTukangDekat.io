<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('payments', function (Blueprint $table) {
            if (!Schema::hasColumn('payments', 'qris_captured_at')) {
                // Pastikan dependency kolom qris_image ada dulu
                if (!Schema::hasColumn('payments', 'qris_image')) {
                    $table->text('qris_image')->nullable()->after('external_payment_id');
                }
                $table->timestamp('qris_captured_at')->nullable()->after('qris_image');
            }
        });
    }


    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn('qris_captured_at');
        });
    }
};
