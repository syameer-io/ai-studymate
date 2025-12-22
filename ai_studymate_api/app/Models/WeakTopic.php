<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * WeakTopic Model
 *
 * Represents a topic the user struggles with based on flashcard performance.
 */
class WeakTopic extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'subject',
        'topic',
        'accuracy',
        'total_attempts',
        'last_attempted_at',
    ];

    protected $casts = [
        'accuracy' => 'decimal:2',
        'total_attempts' => 'integer',
        'last_attempted_at' => 'datetime',
    ];

    /**
     * Relationship: Weak topic belongs to a user
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope: Get topics below threshold accuracy
     */
    public function scopeStruggling($query, $threshold = 60)
    {
        return $query->where('accuracy', '<', $threshold);
    }
}
