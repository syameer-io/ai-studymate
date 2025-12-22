<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Exams Table Migration
 *
 * Stores exam information with dates, locations, and syllabus.
 * Used for countdown timers and study plan generation.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('exams', function (Blueprint $table) {
            // Primary key
            $table->id();

            // Foreign key to users table
            $table->foreignId('user_id')
                  ->constrained()
                  ->onDelete('cascade');

            // Exam details
            $table->string('name');           // "ITT632 Final Exam"
            $table->string('subject');         // "ITT632"
            $table->date('exam_date');         // When the exam is
            $table->time('exam_time')->nullable(); // Time of exam (optional)
            $table->string('location')->nullable(); // "Hall A" (optional)

            // Syllabus as JSON array
            // Example: ["Chapter 1", "Chapter 2", "Chapter 3"]
            $table->json('syllabus')->nullable();

            // Reminder days as JSON array
            // Example: [7, 3, 1] means remind 7, 3, and 1 days before
            // Default handled in Model since MySQL doesn't allow JSON defaults
            $table->json('reminder_days')->nullable();

            // Has the exam been completed?
            $table->boolean('is_completed')->default(false);

            $table->timestamps();

            // Index for faster queries
            $table->index(['user_id', 'exam_date']);
            $table->index(['user_id', 'is_completed']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('exams');
    }
};
