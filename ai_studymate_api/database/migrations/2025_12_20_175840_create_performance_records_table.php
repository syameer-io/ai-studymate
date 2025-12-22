<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Performance Records Table Migration
 *
 * Stores individual flashcard attempt results.
 * Used to track learning progress and identify weak topics.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('performance_records', function (Blueprint $table) {
            // Primary key
            $table->id();

            // Foreign key to users table
            $table->foreignId('user_id')
                  ->constrained()
                  ->onDelete('cascade');

            // Flashcard ID from Firestore
            // We store this as string since Firestore uses string IDs
            $table->string('flashcard_id', 128);

            // Subject and topic for analytics
            $table->string('subject')->nullable();
            $table->string('topic')->nullable();

            // Was the answer correct?
            $table->boolean('is_correct');

            // How long did the user take to answer? (in seconds)
            $table->decimal('response_time', 5, 2)->nullable();

            // When was this attempt made?
            $table->timestamp('attempted_at')->useCurrent();

            // Indexes for analytics queries
            $table->index(['user_id', 'subject']);
            $table->index(['user_id', 'flashcard_id']);
            $table->index('attempted_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('performance_records');
    }
};
