<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('wilayah_kota', function (Blueprint $table) {
            $table->id();
            $table->string('name', 120)->unique();
            $table->timestamps();
        });

        Schema::create('wilayah_kecamatan', function (Blueprint $table) {
            $table->id();
            $table->foreignId('kota_id')->constrained('wilayah_kota')->onDelete('cascade');
            $table->string('name', 120);
            $table->timestamps();

            $table->unique(['kota_id', 'name']);
            $table->index('kota_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wilayah_kecamatan');
        Schema::dropIfExists('wilayah_kota');
    }
};
