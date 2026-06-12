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
    Schema::create('processed_webhook_events', function (Blueprint $table) {
      $table->id();
      $table->string('event_hash', 128)->unique();
      $table->string('driver', 50)->nullable();
      $table->string('external_id', 200)->nullable()->index();
      $table->string('status', 50)->nullable();
      $table->timestamps();
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('processed_webhook_events');
  }
};
