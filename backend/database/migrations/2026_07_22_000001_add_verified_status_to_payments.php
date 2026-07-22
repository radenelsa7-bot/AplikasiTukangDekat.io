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
        Schema::table('payments', function (Blueprint $table) {
            // Drop the old enum constraint and recreate with VERIFIED status
            // Note: MySQL doesn't support altering enum directly in all versions
            // This migration adds VERIFIED as an additional paid-like status
        });
        
        // For MySQL, we need to modify the enum column
        \Illuminate\Support\Facades\DB::statement("
            ALTER TABLE payments 
            MODIFY COLUMN status 
            ENUM('UNPAID', 'PENDING', 'PAID', 'FAILED', 'EXPIRED', 'VERIFIED') 
            DEFAULT 'UNPAID'
        ");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        \Illuminate\Support\Facades\DB::statement("
            ALTER TABLE payments 
            MODIFY COLUMN status 
            ENUM('UNPAID', 'PENDING', 'PAID', 'FAILED', 'EXPIRED') 
            DEFAULT 'UNPAID'
        ");
    }
};