<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
  public function up()
  {
    Schema::table('payments', function (Blueprint $table) {
      // Only add columns if provider_payout already exists
      if (Schema::hasColumn('payments', 'provider_payout')) {
        if (!Schema::hasColumn('payments', 'provider_payout_processed')) {
          $table->boolean('provider_payout_processed')->default(false)->after('provider_payout');
        }
        if (!Schema::hasColumn('payments', 'provider_paid_at')) {
          $table->timestamp('provider_paid_at')->nullable()->after('provider_payout_processed');
        }
      }
    });
  }

    public function down()
    {
        Schema::table('payments', function (Blueprint $table) {
            if (Schema::hasColumn('payments', 'provider_paid_at')) {
                $table->dropColumn('provider_paid_at');
            }
            if (Schema::hasColumn('payments', 'provider_payout_processed')) {
                $table->dropColumn('provider_payout_processed');
            }
        });
    }
};
