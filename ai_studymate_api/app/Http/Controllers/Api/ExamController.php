<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exam;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

/**
 * Exam API Controller
 *
 * Handles CRUD operations for exams.
 */
class ExamController extends Controller
{
    /**
     * List all exams for a user
     *
     * GET /api/exams
     */
    public function index(Request $request): JsonResponse
    {
        $user = $this->getUserFromRequest($request);

        if (!$user) {
            return $this->userNotFoundResponse();
        }

        $exams = $user->exams()->orderBy('exam_date')->get();

        return response()->json([
            'success' => true,
            'data' => $exams,
        ]);
    }

    /**
     * Get upcoming exams only
     *
     * GET /api/exams/upcoming
     */
    public function upcoming(Request $request): JsonResponse
    {
        $user = $this->getUserFromRequest($request);

        if (!$user) {
            return $this->userNotFoundResponse();
        }

        $exams = $user->exams()
            ->where('is_completed', false)
            ->where('exam_date', '>=', now()->toDateString())
            ->orderBy('exam_date')
            ->take(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $exams,
        ]);
    }

    /**
     * Create a new exam
     *
     * POST /api/exams
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'userId' => 'required|string',
            'name' => 'required|string|max:255',
            'subject' => 'required|string|max:255',
            'date' => 'required|date|after:today',
            'time' => 'nullable|date_format:H:i',
            'location' => 'nullable|string|max:255',
            'syllabus' => 'nullable|array',
            'reminderDays' => 'nullable|array',
        ]);

        $user = $this->getOrCreateUser($validated['userId'], $request);

        $exam = Exam::create([
            'user_id' => $user->id,
            'name' => $validated['name'],
            'subject' => $validated['subject'],
            'exam_date' => $validated['date'],
            'exam_time' => $validated['time'] ?? null,
            'location' => $validated['location'] ?? null,
            'syllabus' => $validated['syllabus'] ?? [],
            'reminder_days' => $validated['reminderDays'] ?? [7, 3, 1],
        ]);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $exam->id,
                'name' => $exam->name,
                'daysRemaining' => $exam->days_remaining,
                'message' => 'Exam added successfully. Reminders set.',
            ],
        ], 201);
    }

    /**
     * Get a specific exam
     *
     * GET /api/exams/{id}
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $user = $this->getUserFromRequest($request);

        if (!$user) {
            return $this->userNotFoundResponse();
        }

        $exam = $user->exams()->find($id);

        if (!$exam) {
            return response()->json([
                'success' => false,
                'message' => 'Exam not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $exam,
        ]);
    }

    /**
     * Update an exam
     *
     * PUT /api/exams/{id}
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $user = $this->getUserFromRequest($request);

        if (!$user) {
            return $this->userNotFoundResponse();
        }

        $exam = $user->exams()->find($id);

        if (!$exam) {
            return response()->json([
                'success' => false,
                'message' => 'Exam not found',
            ], 404);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'subject' => 'sometimes|string|max:255',
            'date' => 'sometimes|date',
            'time' => 'nullable|date_format:H:i',
            'location' => 'nullable|string|max:255',
            'syllabus' => 'nullable|array',
            'reminderDays' => 'nullable|array',
            'isCompleted' => 'sometimes|boolean',
        ]);

        // Map camelCase to snake_case
        $updateData = [];
        if (isset($validated['name'])) $updateData['name'] = $validated['name'];
        if (isset($validated['subject'])) $updateData['subject'] = $validated['subject'];
        if (isset($validated['date'])) $updateData['exam_date'] = $validated['date'];
        if (isset($validated['time'])) $updateData['exam_time'] = $validated['time'];
        if (isset($validated['location'])) $updateData['location'] = $validated['location'];
        if (isset($validated['syllabus'])) $updateData['syllabus'] = $validated['syllabus'];
        if (isset($validated['reminderDays'])) $updateData['reminder_days'] = $validated['reminderDays'];
        if (isset($validated['isCompleted'])) $updateData['is_completed'] = $validated['isCompleted'];

        $exam->update($updateData);

        return response()->json([
            'success' => true,
            'data' => $exam->fresh(),
        ]);
    }

    /**
     * Delete an exam
     *
     * DELETE /api/exams/{id}
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $user = $this->getUserFromRequest($request);

        if (!$user) {
            return $this->userNotFoundResponse();
        }

        $exam = $user->exams()->find($id);

        if (!$exam) {
            return response()->json([
                'success' => false,
                'message' => 'Exam not found',
            ], 404);
        }

        $exam->delete();

        return response()->json([
            'success' => true,
            'message' => 'Exam deleted successfully',
        ]);
    }

    // ========== HELPER METHODS ==========

    private function getUserFromRequest(Request $request): ?User
    {
        $firebaseUid = $request->input('userId') ?? $request->query('userId');
        if (!$firebaseUid) return null;
        return User::where('firebase_uid', $firebaseUid)->first();
    }

    private function getOrCreateUser(string $firebaseUid, Request $request): User
    {
        return User::firstOrCreate(
            ['firebase_uid' => $firebaseUid],
            [
                'email' => $request->input('email', 'unknown@example.com'),
                'display_name' => $request->input('displayName'),
            ]
        );
    }

    private function userNotFoundResponse(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'User not found. Please provide userId.',
        ], 400);
    }
}
