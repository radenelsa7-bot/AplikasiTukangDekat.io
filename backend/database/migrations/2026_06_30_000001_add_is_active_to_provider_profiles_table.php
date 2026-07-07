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
    Schema::table('provider_profiles', function (Blueprint $table) {
      if (!Schema::hasColumn('provider_profiles', 'is_active')) {
        $table->boolean('is_active')->default(true)->after('is_verified');
      }
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::table('provider_profiles', function (Blueprint $table) {
      $table->dropColumn('is_active');
    });
  }
};
