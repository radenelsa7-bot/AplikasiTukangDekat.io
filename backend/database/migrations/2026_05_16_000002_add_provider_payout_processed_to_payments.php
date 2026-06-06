<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::table('payments', function (Blueprint $table) {
            // Fail-safe: pastikan kolom-kolom payout ada walaupun migrasi urutan/ kondisi sebelumnya tidak sesuai.
            // Beberapa environment/test bisa mengeksekusi migration dengan urutan yang tidak ideal.

            if (!Schema::hasColumn('payments', 'provider_payout')) {
                // Jangan bergantung pada kolom lain (mis. platform_fee) karena pada beberapa environment/test
                // kolom tersebut belum ada.
                $table->unsignedInteger('provider_payout')->default(0);
            }


            if (!Schema::hasColumn('payments', 'provider_payout_processed')) {
                $after = Schema::hasColumn('payments', 'provider_payout') ? 'provider_payout' : null;
                if ($after) {
                    $table->boolean('provider_payout_processed')->default(false)->after($after);
                } else {
                    $table->boolean('provider_payout_processed')->default(false);
                }
            }

            if (!Schema::hasColumn('payments', 'provider_paid_at')) {
                if (Schema::hasColumn('payments', 'provider_payout_processed')) {
                    $table->timestamp('provider_paid_at')->nullable()->after('provider_payout_processed');
                } else {
                    $table->timestamp('provider_paid_at')->nullable()->after('provider_payout');
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
