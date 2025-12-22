<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\StudyPlanController;
use App\Http\Controllers\Api\ExamController;
use App\Http\Controllers\Api\PerformanceController;
use App\Http\Controllers\Api\SearchController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| All routes are prefixed with /api
| Example: POST /api/study-plan/generate
|
*/

// Health check endpoint
Route::get('/health', function () {
    return response()->json([
        'success' => true,
        'message' => 'AI StudyMate API is running',
        'version' => '1.0.0',
        'timestamp' => now()->toIso8601String(),
    ]);
});

// Study Plan routes
Route::prefix('study-plan')->group(function () {
    Route::get('/', [StudyPlanController::class, 'index']);
    Route::post('/generate', [StudyPlanController::class, 'generate']);
    Route::get('/{id}', [StudyPlanController::class, 'show']);
    Route::put('/{id}', [StudyPlanController::class, 'update']);
    Route::delete('/{id}', [StudyPlanController::class, 'destroy']);
});

// Exam routes
Route::prefix('exams')->group(function () {
    Route::get('/', [ExamController::class, 'index']);
    Route::get('/upcoming', [ExamController::class, 'upcoming']);
    Route::post('/', [ExamController::class, 'store']);
    Route::get('/{id}', [ExamController::class, 'show']);
    Route::put('/{id}', [ExamController::class, 'update']);
    Route::delete('/{id}', [ExamController::class, 'destroy']);
});

// Performance routes (placeholders)
Route::prefix('performance')->group(function () {
    Route::post('/update-score', [PerformanceController::class, 'updateScore']);
    Route::get('/weak-topics', [PerformanceController::class, 'weakTopics']);
    Route::get('/statistics', [PerformanceController::class, 'statistics']);
});

// Search route (placeholder)
Route::get('/search', [SearchController::class, 'search']);
