<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

/**
 * Exam Model
 *
 * Represents an exam with date, time, location, and syllabus.
 */
class Exam extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'subject',
        'exam_date',
        'exam_time',
        'location',
        'syllabus',
        'reminder_days',
        'is_completed',
    ];

    protected $casts = [
        'exam_date' => 'date',
        'syllabus' => 'array',
        'reminder_days' => 'array',
        'is_completed' => 'boolean',
    ];

    /**
     * Appended attributes (calculated fields added to JSON)
     */
    protected $appends = ['days_remaining'];

    /**
     * Default attribute values
     */
    protected $attributes = [
        'reminder_days' => '[7, 3, 1]',
    ];

    /**
     * Relationship: Exam belongs to a user
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Calculate days remaining until exam
     *
     * @return int Days remaining (negative if past)
     */
    public function getDaysRemainingAttribute(): int
    {
        return Carbon::now()->startOfDay()->diffInDays($this->exam_date, false);
    }
}
