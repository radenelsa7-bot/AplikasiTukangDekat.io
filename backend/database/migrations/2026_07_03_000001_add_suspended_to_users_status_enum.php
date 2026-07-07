<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'status')) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `users` MODIFY `status` ENUM('ACTIVE', 'INACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVE'");
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'status')) {
            DB::table('users')->where('status', 'SUSPENDED')->update(['status' => 'INACTIVE']);
            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `users` MODIFY `status` ENUM('ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE'");
            }
        }
    }
};
