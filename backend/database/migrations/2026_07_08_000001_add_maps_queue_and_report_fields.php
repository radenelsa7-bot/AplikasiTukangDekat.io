<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('provider_profiles', function (Blueprint $table) {
            if (!Schema::hasColumn('provider_profiles', 'latitude')) {
                $table->decimal('latitude', 10, 7)->nullable()->after('address');
            }
            if (!Schema::hasColumn('provider_profiles', 'longitude')) {
                $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
            }
            if (!Schema::hasColumn('provider_profiles', 'availability_status')) {
                $table->string('availability_status', 30)->default('AVAILABLE')->after('avg_rating');
            }
        });

        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'customer_latitude')) {
                $table->decimal('customer_latitude', 10, 7)->nullable()->after('address');
            }
            if (!Schema::hasColumn('orders', 'customer_longitude')) {
                $table->decimal('customer_longitude', 10, 7)->nullable()->after('customer_latitude');
            }
            if (!Schema::hasColumn('orders', 'provider_latitude')) {
                $table->decimal('provider_latitude', 10, 7)->nullable()->after('customer_longitude');
            }
            if (!Schema::hasColumn('orders', 'provider_longitude')) {
                $table->decimal('provider_longitude', 10, 7)->nullable()->after('provider_latitude');
            }
            if (!Schema::hasColumn('orders', 'damage_level')) {
                $table->string('damage_level', 20)->nullable()->after('notes');
            }
            if (!Schema::hasColumn('orders', 'damage_description')) {
                $table->text('damage_description')->nullable()->after('damage_level');
            }
            if (!Schema::hasColumn('orders', 'estimated_price_min')) {
                $table->unsignedInteger('estimated_price_min')->nullable()->after('damage_description');
            }
            if (!Schema::hasColumn('orders', 'estimated_price_max')) {
                $table->unsignedInteger('estimated_price_max')->nullable()->after('estimated_price_min');
            }
            if (!Schema::hasColumn('orders', 'queue_note')) {
                $table->string('queue_note')->nullable()->after('status');
            }
        });

        Schema::table('order_attachments', function (Blueprint $table) {
            if (!Schema::hasColumn('order_attachments', 'purpose')) {
                $table->string('purpose', 40)->default('CUSTOMER_DAMAGE')->after('file_type');
            }
        });
    }

    public function down(): void
    {
        Schema::table('order_attachments', function (Blueprint $table) {
            if (Schema::hasColumn('order_attachments', 'purpose')) {
                $table->dropColumn('purpose');
            }
        });

        Schema::table('orders', function (Blueprint $table) {
            foreach ([
                'customer_latitude',
                'customer_longitude',
                'provider_latitude',
                'provider_longitude',
                'damage_level',
                'damage_description',
                'estimated_price_min',
                'estimated_price_max',
                'queue_note',
            ] as $column) {
                if (Schema::hasColumn('orders', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        Schema::table('provider_profiles', function (Blueprint $table) {
            foreach (['latitude', 'longitude', 'availability_status'] as $column) {
                if (Schema::hasColumn('provider_profiles', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
