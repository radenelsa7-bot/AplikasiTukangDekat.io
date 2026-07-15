<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
  /**
   * Run the migrations.
   */
  public function up(): void
  {
    // Modify the enum to include SUSPENDED
    if (DB::getDriverName() === 'mysql' && Schema::hasTable('users')) {
      // Use raw statement to modify enum safely for MySQL
      DB::statement("ALTER TABLE `users` MODIFY `status` ENUM('ACTIVE','INACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE'");
    }
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    if (DB::getDriverName() === 'mysql' && Schema::hasTable('users')) {
      DB::statement("ALTER TABLE `users` MODIFY `status` ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE'");
    }
  }
};
