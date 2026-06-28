<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::table('users', function (Blueprint $table) {
      $table->string('full_name')->nullable()->after('name');
      $table->string('phone_number')->nullable()->after('phone');
      $table->string('profile_photo_path')->nullable()->after('phone_number');
    });
  }

  public function down(): void
  {
    Schema::table('users', function (Blueprint $table) {
      $table->dropColumn(['full_name', 'phone_number', 'profile_photo_path']);
    });
  }
};
