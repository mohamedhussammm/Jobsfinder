const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema(
    {
        raterUserId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Rater user is required'],
        },
        ratedUserId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Rated user is required'],
        },
        eventId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Event',
        },
        score: {
            type: Number,
            required: [true, 'Rating score is required'],
            min: [1, 'Score must be at least 1'],
            max: [5, 'Score must be at most 5'],
        },
        textReview: {
            type: String,
            trim: true,
        },
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

// One rating per rater per user per event
ratingSchema.index({ raterUserId: 1, ratedUserId: 1, eventId: 1 }, { unique: true });
ratingSchema.index({ ratedUserId: 1 });
ratingSchema.index({ eventId: 1 });

// ─── Prevent self-rating ────────────────────────
ratingSchema.pre('validate', function (next) {
    if (this.raterUserId && this.ratedUserId && this.raterUserId.equals(this.ratedUserId)) {
        this.invalidate('ratedUserId', 'You cannot rate yourself');
    }
    next();
});

module.exports = mongoose.model('Rating', ratingSchema);
