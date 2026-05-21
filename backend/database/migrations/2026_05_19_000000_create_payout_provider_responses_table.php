<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
  public function up()
  {
    Schema::create('payout_provider_responses', function (Blueprint $table) {
      $table->id();
      $table->string('provider');
      $table->string('transaction_reference')->nullable();
      $table->text('path')->nullable();
      $table->longText('request_body')->nullable();
      $table->longText('response_body')->nullable();
      $table->integer('status_code')->nullable();
      $table->timestamps();
    });
  }

  public function down()
  {
    Schema::dropIfExists('payout_provider_responses');
  }
};
