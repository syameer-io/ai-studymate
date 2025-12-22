<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

/**
 * Search API Controller (Placeholder)
 *
 * Will be fully implemented in Phase 4.
 */
class SearchController extends Controller
{
    public function search(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Coming soon in Phase 4',
        ], 501);
    }
}
