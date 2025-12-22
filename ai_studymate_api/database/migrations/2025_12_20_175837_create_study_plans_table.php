<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Study Plans Table Migration
 *
 * Stores personalized study plans generated for users.
 * Each plan contains a JSON schedule with daily tasks.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('study_plans', function (Blueprint $table) {
            // Primary key
            $table->id();

            // Foreign key to users table
            $table->foreignId('user_id')
                  ->constrained()
                  ->onDelete('cascade'); // Delete plans when user is deleted

            // Plan title (e.g., "Study Plan - July 2025")
            $table->string('title');

            // JSON schedule containing daily tasks
            // Example: [{"date": "2025-07-01", "tasks": [...]}]
            $table->json('schedule');

            // Plan date range
            $table->date('start_date');
            $table->date('end_date');

            // Is this the active plan? (user can have multiple, only one active)
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            // Index for faster user queries
            $table->index(['user_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('study_plans');
    }
};
