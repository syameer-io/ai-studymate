<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

/**
 * Performance API Controller (Placeholder)
 *
 * Will be fully implemented in Phase 4.
 */
class PerformanceController extends Controller
{
    public function updateScore(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Coming soon in Phase 4',
        ], 501);
    }

    public function weakTopics(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Coming soon in Phase 4',
        ], 501);
    }

    public function statistics(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Coming soon in Phase 4',
        ], 501);
    }
}
