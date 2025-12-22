<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * User Model
 *
 * Represents a user synced from Firebase Auth.
 * Contains relationships to all user-owned data.
 */
class User extends Authenticatable
{
    use HasFactory;

    /**
     * Mass assignable attributes
     *
     * These fields can be set using User::create([...])
     */
    protected $fillable = [
        'firebase_uid',
        'email',
        'display_name',
    ];

    /**
     * Hidden attributes (not included in JSON responses)
     */
    protected $hidden = [];

    /**
     * Relationship: User has many study plans
     */
    public function studyPlans(): HasMany
    {
        return $this->hasMany(StudyPlan::class);
    }

    /**
     * Relationship: User has many exams
     */
    public function exams(): HasMany
    {
        return $this->hasMany(Exam::class);
    }

    /**
     * Relationship: User has many performance records
     */
    public function performanceRecords(): HasMany
    {
        return $this->hasMany(PerformanceRecord::class);
    }

    /**
     * Relationship: User has many weak topics
     */
    public function weakTopics(): HasMany
    {
        return $this->hasMany(WeakTopic::class);
    }

    /**
     * Get the active study plan for this user
     */
    public function activeStudyPlan()
    {
        return $this->studyPlans()->where('is_active', true)->first();
    }

    /**
     * Get upcoming exams (not completed, future date)
     */
    public function upcomingExams()
    {
        return $this->exams()
            ->where('is_completed', false)
            ->where('exam_date', '>=', now())
            ->orderBy('exam_date')
            ->get();
    }
}
