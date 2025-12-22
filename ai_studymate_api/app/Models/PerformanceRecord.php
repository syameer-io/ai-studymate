<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * PerformanceRecord Model
 *
 * Represents a single flashcard attempt by a user.
 */
class PerformanceRecord extends Model
{
    use HasFactory;

    // Disable default timestamps since we use 'attempted_at'
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'flashcard_id',
        'subject',
        'topic',
        'is_correct',
        'response_time',
        'attempted_at',
    ];

    protected $casts = [
        'is_correct' => 'boolean',
        'response_time' => 'decimal:2',
        'attempted_at' => 'datetime',
    ];

    /**
     * Relationship: Record belongs to a user
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
