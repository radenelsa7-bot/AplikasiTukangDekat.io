<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('kota_id')->nullable()->after('provider_id')->constrained('wilayah_kota')->nullOnDelete();
            $table->foreignId('kecamatan_id')->nullable()->after('kota_id')->constrained('wilayah_kecamatan')->nullOnDelete();

            $table->index('kota_id');
            $table->index('kecamatan_id');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('kecamatan_id');
            $table->dropConstrainedForeignId('kota_id');
            $table->index(['kota_id']);
            $table->index(['kecamatan_id']);
        });
    }
};
