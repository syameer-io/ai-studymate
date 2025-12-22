<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * StudyPlan Model
 *
 * Represents a personalized study schedule for a user.
 */
class StudyPlan extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'title',
        'schedule',
        'start_date',
        'end_date',
        'is_active',
    ];

    /**
     * Cast attributes to specific types
     *
     * 'schedule' is stored as JSON in database but we want it as array in PHP
     */
    protected $casts = [
        'schedule' => 'array',
        'start_date' => 'date',
        'end_date' => 'date',
        'is_active' => 'boolean',
    ];

    /**
     * Relationship: Study plan belongs to a user
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
