<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StudyPlan;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

/**
 * Study Plan API Controller
 *
 * Handles CRUD operations and study plan generation.
 */
class StudyPlanController extends Controller
{
    /**
     * Get all study plans for a user
     *
     * GET /api/study-plan
     */
    public function index(Request $request): JsonResponse
    {
        $firebaseUid = $request->input('userId') ?? $request->query('userId');

        if (!$firebaseUid) {
            return $this->userNotFoundResponse();
        }

        // Get or create user
        $user = $this->getOrCreateUser($firebaseUid, $request);

        if (!$user) {
            return $this->userNotFoundResponse();
        }

        $plans = $user->studyPlans()->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $plans,
        ]);
    }

    /**
     * Generate a new study plan
     *
     * POST /api/study-plan/generate
     */
    public function generate(Request $request): JsonResponse
    {
        // Validate request data
        $validated = $request->validate([
            'userId' => 'required|string',
            'subjects' => 'required|array|min:1',
            'subjects.*.name' => 'required|string',
            'subjects.*.difficulty' => 'required|in:easy,medium,hard',
            'subjects.*.examDate' => 'required|date',
            'availableHoursPerDay' => 'required|integer|min:1|max:12',
            'preferredStudyTime' => 'required|in:morning,afternoon,evening,night',
        ]);

        // Get or create user
        $user = $this->getOrCreateUser($validated['userId'], $request);

        if (!$user) {
            return $this->userNotFoundResponse();
        }

        // Deactivate existing plans
        $user->studyPlans()->update(['is_active' => false]);

        // Generate schedule
        $schedule = $this->calculateSchedule($validated);
        $endDate = collect($validated['subjects'])->pluck('examDate')->max();

        // Create new plan
        $studyPlan = StudyPlan::create([
            'user_id' => $user->id,
            'title' => 'Study Plan - ' . now()->format('M Y'),
            'schedule' => $schedule,
            'start_date' => now()->toDateString(),
            'end_date' => $endDate,
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $studyPlan->id,
                'schedule' => $schedule,
                'recommendations' => $this->getRecommendations($validated),
            ],
        ], 201);
    }

    /**
     * Get a specific study plan
     *
     * GET /api/study-plan/{id}
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $firebaseUid = $request->input('userId') ?? $request->query('userId');

        if (!$firebaseUid) {
            return $this->userNotFoundResponse();
        }

        $user = $this->getOrCreateUser($firebaseUid, $request);

        if (!$user) {
            return $this->userNotFoundResponse();
        }

        $plan = $user->studyPlans()->find($id);

        if (!$plan) {
            return response()->json([
                'success' => false,
                'message' => 'Study plan not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $plan,
        ]);
    }

    /**
     * Update a study plan
     *
     * PUT /api/study-plan/{id}
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $firebaseUid = $request->input('userId') ?? $request->query('userId');

        if (!$firebaseUid) {
            return $this->userNotFoundResponse();
        }

        $user = $this->getOrCreateUser($firebaseUid, $request);

        if (!$user) {
            return $this->userNotFoundResponse();
        }

        $plan = $user->studyPlans()->find($id);

        if (!$plan) {
            return response()->json([
                'success' => false,
                'message' => 'Study plan not found',
            ], 404);
        }

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'schedule' => 'sometimes|array',
            'is_active' => 'sometimes|boolean',
        ]);

        // If activating this plan, deactivate others
        if (isset($validated['is_active']) && $validated['is_active']) {
            $user->studyPlans()->where('id', '!=', $id)->update(['is_active' => false]);
        }

        $plan->update($validated);

        return response()->json([
            'success' => true,
            'data' => $plan->fresh(),
        ]);
    }

    /**
     * Delete a study plan
     *
     * DELETE /api/study-plan/{id}
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $firebaseUid = $request->input('userId') ?? $request->query('userId');

        if (!$firebaseUid) {
            return $this->userNotFoundResponse();
        }

        $user = $this->getOrCreateUser($firebaseUid, $request);

        if (!$user) {
            return $this->userNotFoundResponse();
        }

        $plan = $user->studyPlans()->find($id);

        if (!$plan) {
            return response()->json([
                'success' => false,
                'message' => 'Study plan not found',
            ], 404);
        }

        $plan->delete();

        return response()->json([
            'success' => true,
            'message' => 'Study plan deleted successfully',
        ]);
    }

    // ========== HELPER METHODS ==========

    /**
     * Get user from Firebase UID in request
     */
    private function getUserFromFirebaseUid(Request $request): ?User
    {
        $firebaseUid = $request->input('userId') ?? $request->query('userId');

        if (!$firebaseUid) {
            return null;
        }

        return User::where('firebase_uid', $firebaseUid)->first();
    }

    /**
     * Get or create user from Firebase UID
     */
    private function getOrCreateUser(string $firebaseUid, Request $request): ?User
    {
        return User::firstOrCreate(
            ['firebase_uid' => $firebaseUid],
            [
                'email' => $request->input('email', 'unknown@example.com'),
                'display_name' => $request->input('displayName'),
            ]
        );
    }

    /**
     * Return standard user not found response
     */
    private function userNotFoundResponse(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'User not found. Please provide userId.',
        ], 400);
    }

    /**
     * Calculate study schedule based on subjects and preferences
     *
     * This is a simplified algorithm. In production, you'd want
     * more sophisticated scheduling logic.
     */
    private function calculateSchedule(array $data): array
    {
        $schedule = [];
        $subjects = collect($data['subjects']);
        $hoursPerDay = $data['availableHoursPerDay'];
        $preferredTime = $data['preferredStudyTime'];

        // Get start time based on preference
        $startTimes = [
            'morning' => '08:00',
            'afternoon' => '14:00',
            'evening' => '18:00',
            'night' => '20:00',
        ];
        $startTime = $startTimes[$preferredTime];

        // Calculate days until each exam
        $now = now();
        $sortedSubjects = $subjects->map(function ($subject) use ($now) {
            $subject['daysUntilExam'] = $now->diffInDays($subject['examDate']);
            return $subject;
        })->sortBy('daysUntilExam');

        // Assign difficulty weights
        $weights = ['easy' => 1, 'medium' => 2, 'hard' => 3];
        $totalWeight = $sortedSubjects->sum(fn($s) => $weights[$s['difficulty']]);

        // Generate daily schedule for next 14 days (or until first exam)
        $daysToSchedule = min(14, $sortedSubjects->first()['daysUntilExam'] ?? 14);

        for ($day = 0; $day < $daysToSchedule; $day++) {
            $date = $now->copy()->addDays($day)->format('Y-m-d');
            $tasks = [];
            $remainingHours = $hoursPerDay;

            foreach ($sortedSubjects as $subject) {
                if ($remainingHours <= 0) break;

                $subjectWeight = $weights[$subject['difficulty']];
                $subjectHours = round(($subjectWeight / $totalWeight) * $hoursPerDay);
                $subjectHours = min($subjectHours, $remainingHours);

                if ($subjectHours > 0) {
                    $tasks[] = [
                        'subject' => $subject['name'],
                        'topic' => 'Review session ' . ($day + 1),
                        'duration' => $subjectHours,
                        'startTime' => $startTime,
                    ];
                    $remainingHours -= $subjectHours;
                }
            }

            $schedule[] = [
                'date' => $date,
                'tasks' => $tasks,
            ];
        }

        return $schedule;
    }

    /**
     * Generate recommendations based on subjects
     */
    private function getRecommendations(array $data): array
    {
        $recommendations = [];

        foreach ($data['subjects'] as $subject) {
            if ($subject['difficulty'] === 'hard') {
                $recommendations[] = "Focus more on {$subject['name']} due to higher difficulty";
            }
        }

        $recommendations[] = "Review weak topics identified from flashcard performance";
        $recommendations[] = "Take breaks every 25 minutes (Pomodoro technique)";

        return $recommendations;
    }
}
