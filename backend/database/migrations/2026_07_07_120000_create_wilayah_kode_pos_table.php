<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wilayah_kode_pos', function (Blueprint $table) {
            $table->id();
            $table->string('kode_pos', 12)->unique();

            // Designed as "Kode Pos -> menentukan kota & kecamatan".
            $table->foreignId('kota_id')->constrained('wilayah_kota')->cascadeOnDelete();
            $table->foreignId('kecamatan_id')->constrained('wilayah_kecamatan')->cascadeOnDelete();

            $table->timestamps();

            $table->index(['kota_id', 'kecamatan_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wilayah_kode_pos');
    }
};

