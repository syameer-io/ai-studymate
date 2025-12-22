<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Weak Topics Table Migration
 *
 * Stores calculated weak topics based on flashcard performance.
 * Updated periodically when user studies flashcards.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('weak_topics', function (Blueprint $table) {
            // Primary key
            $table->id();

            // Foreign key to users table
            $table->foreignId('user_id')
                  ->constrained()
                  ->onDelete('cascade');

            // Topic identification
            $table->string('subject');
            $table->string('topic');

            // Performance metrics
            $table->decimal('accuracy', 5, 2); // Percentage (0-100)
            $table->integer('total_attempts')->default(0);

            // When was this topic last attempted?
            $table->timestamp('last_attempted_at')->nullable();

            $table->timestamps();

            // Unique constraint - one entry per user/subject/topic
            $table->unique(['user_id', 'subject', 'topic']);

            // Index for queries
            $table->index(['user_id', 'accuracy']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('weak_topics');
    }
};
