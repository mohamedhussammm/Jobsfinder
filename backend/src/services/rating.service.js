const Rating = require('../models/Rating');
const User = require('../models/User');
const Notification = require('../models/Notification');
const AppError = require('../utils/AppError');

/**
 * Submit a rating and auto-update user's average.
 */
const createRating = async (raterUserId, data) => {
    const { ratedUserId, eventId, score, textReview } = data;

    try {
        const rating = await Rating.create({
            raterUserId,
            ratedUserId,
            eventId,
            score,
            textReview,
        });

        // ─── Update user's average rating ───────
        const agg = await Rating.aggregate([
            { $match: { ratedUserId: rating.ratedUserId } },
            {
                $group: {
                    _id: '$ratedUserId',
                    avgScore: { $avg: '$score' },
                    count: { $sum: 1 },
                },
            },
        ]);

        if (agg.length > 0) {
            await User.findByIdAndUpdate(ratedUserId, {
                ratingAvg: Math.round(agg[0].avgScore * 100) / 100,
                ratingCount: agg[0].count,
            });
        }

        // ─── Notify rated user ──────────────────
        await Notification.create({
            userId: ratedUserId,
            type: 'rating',
            relatedId: rating._id,
            title: 'New Rating Received',
            message: `You received a rating of ${score}/5`,
        });

        return rating;
    } catch (err) {
        if (err.code === 11000) {
            throw new AppError('You have already rated this user for this event', 400);
        }
        throw err;
    }
};

const getUserRatings = async (userId) => {
    return Rating.find({ ratedUserId: userId })
        .populate('raterUserId', 'name avatarPath')
        .populate('eventId', 'title')
        .sort({ createdAt: -1 });
};

const getRatingsGivenByUser = async (userId) => {
    return Rating.find({ raterUserId: userId })
        .populate('ratedUserId', 'name avatarPath')
        .populate('eventId', 'title')
        .sort({ createdAt: -1 });
};

const getEventRatings = async (eventId) => {
    return Rating.find({ eventId })
        .populate('raterUserId', 'name')
        .populate('ratedUserId', 'name')
        .sort({ createdAt: -1 });
};

module.exports = {
    createRating,
    getUserRatings,
    getRatingsGivenByUser,
    getEventRatings,
};
