<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Users Table Migration
 *
 * Stores user information synced from Firebase Auth.
 * We don't store passwords - Firebase handles authentication.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            // Primary key - auto-incrementing ID
            $table->id();

            // Firebase UID - unique identifier from Firebase Auth
            // This links our local user to their Firebase account
            $table->string('firebase_uid', 128)->unique();

            // User's email address from Firebase
            $table->string('email')->unique();

            // Display name (can be null if user didn't set one)
            $table->string('display_name')->nullable();

            // Timestamps for created_at and updated_at
            $table->timestamps();

            // Index for faster lookups by Firebase UID
            $table->index('firebase_uid');
        });

        // These tables come with Laravel but we don't need them
        // Keeping them for session management
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};
