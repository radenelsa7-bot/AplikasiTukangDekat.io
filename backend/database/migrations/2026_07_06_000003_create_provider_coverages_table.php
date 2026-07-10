<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('provider_coverages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('provider_profile_id')->constrained('provider_profiles')->onDelete('cascade');
            $table->foreignId('kecamatan_id')->constrained('wilayah_kecamatan')->onDelete('cascade');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['provider_profile_id', 'kecamatan_id']);
            $table->index('kecamatan_id');
            $table->index('provider_profile_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('provider_coverages');
    }
};
