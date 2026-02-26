const User = require('../models/User');
const Event = require('../models/Event');
const Application = require('../models/Application');
const Rating = require('../models/Rating');

/**
 * Get main dashboard KPIs.
 */
const getKPIs = async () => {
    const [totalUsers, totalEvents, totalApplications, totalRatings, publishedEvents, pendingEvents] =
        await Promise.all([
            User.countDocuments({ deletedAt: null }),
            Event.countDocuments(),
            Application.countDocuments(),
            Rating.countDocuments(),
            Event.countDocuments({ status: 'published' }),
            Event.countDocuments({ status: 'pending' }),
        ]);

    return {
        totalUsers,
        totalEvents,
        totalApplications,
        totalRatings,
        publishedEvents,
        pendingEvents,
    };
};

/**
 * Get monthly statistics for the last N months.
 */
const getMonthlyStats = async (months = 12) => {
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - months);

    const [events, applications] = await Promise.all([
        Event.aggregate([
            { $match: { createdAt: { $gte: startDate } } },
            {
                $group: {
                    _id: {
                        year: { $year: '$createdAt' },
                        month: { $month: '$createdAt' },
                    },
                    count: { $sum: 1 },
                },
            },
            { $sort: { '_id.year': 1, '_id.month': 1 } },
        ]),
        Application.aggregate([
            { $match: { createdAt: { $gte: startDate } } },
            {
                $group: {
                    _id: {
                        year: { $year: '$createdAt' },
                        month: { $month: '$createdAt' },
                    },
                    count: { $sum: 1 },
                },
            },
            { $sort: { '_id.year': 1, '_id.month': 1 } },
        ]),
    ]);

    return { events, applications };
};

/**
 * Get role distribution.
 */
const getRoleDistribution = async () => {
    const counts = await User.aggregate([
        { $match: { deletedAt: null } },
        { $group: { _id: '$role', count: { $sum: 1 } } },
    ]);
    const result = {};
    counts.forEach((c) => { result[c._id] = c.count; });
    return result;
};

/**
 * Get top events by application count.
 */
const getTopEvents = async (limit = 10) => {
    return Application.aggregate([
        { $group: { _id: '$eventId', applicationCount: { $sum: 1 } } },
        { $sort: { applicationCount: -1 } },
        { $limit: limit },
        {
            $lookup: {
                from: 'events',
                localField: '_id',
                foreignField: '_id',
                as: 'event',
            },
        },
        { $unwind: '$event' },
        {
            $project: {
                _id: 0,
                eventId: '$_id',
                title: '$event.title',
                status: '$event.status',
                applicationCount: 1,
            },
        },
    ]);
};

/**
 * Get application status distribution.
 */
const getApplicationStatusDistribution = async () => {
    const counts = await Application.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);
    const result = {};
    counts.forEach((c) => { result[c._id] = c.count; });
    return result;
};

/**
 * Get event status distribution.
 */
const getEventStatusDistribution = async () => {
    const counts = await Event.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);
    const result = {};
    counts.forEach((c) => { result[c._id] = c.count; });
    return result;
};

module.exports = {
    getKPIs,
    getMonthlyStats,
    getRoleDistribution,
    getTopEvents,
    getApplicationStatusDistribution,
    getEventStatusDistribution,
};
