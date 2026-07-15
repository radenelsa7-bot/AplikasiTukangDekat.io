<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Add city_id and district_id for provider location
            if (!Schema::hasColumn('users', 'city_id')) {
                $table->foreignId('city_id')
                    ->nullable()
                    ->constrained('wilayah_kota')
                    ->onDelete('set null')
                    ->after('phone');
            }

            if (!Schema::hasColumn('users', 'district_id')) {
                $table->foreignId('district_id')
                    ->nullable()
                    ->constrained('wilayah_kecamatan')
                    ->onDelete('set null')
                    ->after('city_id');
            }

            // Modify status to support provider approval workflow
            // Change from ACTIVE/INACTIVE/SUSPENDED to pending/approved/rejected for providers
            if (!Schema::hasColumn('users', 'provider_status')) {
                $table->enum('provider_status', ['pending', 'approved', 'rejected'])
                    ->nullable()
                    ->default(null)
                    ->after('district_id')
                    ->comment('Approval status for PROVIDER role. Only for providers with role=PROVIDER');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'provider_status')) {
                $table->dropColumn('provider_status');
            }
            if (Schema::hasColumn('users', 'district_id')) {
                $table->dropForeign(['district_id']);
                $table->dropColumn('district_id');
            }
            if (Schema::hasColumn('users', 'city_id')) {
                $table->dropForeign(['city_id']);
                $table->dropColumn('city_id');
            }
        });
    }
};
