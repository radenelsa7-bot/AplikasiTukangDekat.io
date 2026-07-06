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
    Schema::table('users', function (Blueprint $table) {
      // Tambahkan kolom role jika belum ada
      if (!Schema::hasColumn('users', 'role')) {
        $table->enum('role', ['CUSTOMER', 'PROVIDER', 'ADMIN', 'TREASURER'])->default('CUSTOMER');
      }

      // Tambahkan kolom status jika belum ada
      if (!Schema::hasColumn('users', 'status')) {
        $table->enum('status', ['ACTIVE', 'INACTIVE', 'SUSPENDED'])->default('ACTIVE');
      }

      // Tambahkan phone jika belum ada
      if (!Schema::hasColumn('users', 'phone')) {
        $table->string('phone', 30)->nullable();
      }
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::table('users', function (Blueprint $table) {
      // Revert changes jika diperlukan
    });
  }
};
