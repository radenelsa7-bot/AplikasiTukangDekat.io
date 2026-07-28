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
      $table->unsignedInteger('commission_percent')->default(10)->after('amount');
      $table->unsignedInteger('platform_fee')->default(0)->after('commission_percent');
      $table->unsignedInteger('provider_payout')->default(0)->after('platform_fee');
      $table->string('settlement_status', 30)->default('PENDING')->after('provider_payout');
      $table->dateTime('settled_at')->nullable()->after('paid_at');
      $table->unsignedInteger('refund_amount')->default(0)->after('settled_at');
      $table->string('refund_status', 30)->default('NONE')->after('refund_amount');
      $table->string('refund_reason', 100)->nullable()->after('refund_status');
      $table->dateTime('refund_requested_at')->nullable()->after('refund_reason');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::table('payments', function (Blueprint $table) {
      $table->dropColumn([
        'commission_percent',
        'platform_fee',
        'provider_payout',
        'settlement_status',
        'settled_at',
        'refund_amount',
        'refund_status',
        'refund_reason',
        'refund_requested_at',
      ]);
    });
  }
};
