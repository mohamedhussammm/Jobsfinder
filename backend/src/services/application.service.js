const Application = require('../models/Application');
const Event = require('../models/Event');
const Notification = require('../models/Notification');
const AppError = require('../utils/AppError');
const { parsePagination, paginationMeta } = require('../utils/pagination');

/**
 * Apply to an event (normal user).
 */
const applyToEvent = async (userId, data) => {
    // Check event exists and is published
    const event = await Event.findById(data.eventId);
    if (!event) throw new AppError('Event not found', 404);
    if (event.status !== 'published') {
        throw new AppError('Can only apply to published events', 400);
    }

    // Check capacity
    if (event.capacity) {
        const acceptedCount = await Application.countDocuments({
            eventId: event._id,
            status: 'accepted',
        });
        if (acceptedCount >= event.capacity) {
            throw new AppError('Event has reached maximum capacity', 400);
        }
    }

    // Create application (unique index will handle duplicates)
    try {
        const application = await Application.create({
            userId,
            eventId: data.eventId,
            cvPath: data.cvPath || null,
            coverLetter: data.coverLetter || null,
            experience: data.experience || null,
            isAvailable: data.isAvailable || false,
            openToOtherOptions: data.openToOtherOptions || false,
            status: 'applied',
        });
        return application;
    } catch (err) {
        if (err.code === 11000) {
            throw new AppError('You have already applied to this event', 400);
        }
        throw err;
    }
};

/**
 * Get user's own applications.
 */
const getUserApplications = async (userId, query) => {
    const { skip, limit, page } = parsePagination(query);

    const [applications, total] = await Promise.all([
        Application.find({ userId })
            .populate({
                path: 'eventId',
                select: 'title startTime endTime status imagePath companyId',
                populate: { path: 'companyId', select: 'name logoPath' },
            })
            .skip(skip).limit(limit)
            .sort({ appliedAt: -1 }),
        Application.countDocuments({ userId }),
    ]);

    return { applications, pagination: paginationMeta(total, page, limit) };
};

/**
 * Get applications for an event (company/team_leader/admin).
 */
const getEventApplications = async (eventId, query) => {
    const { skip, limit, page } = parsePagination(query);
    const filter = { eventId };

    if (query.status) filter.status = query.status;

    const [applications, total] = await Promise.all([
        Application.find(filter)
            .populate('userId', 'name email phone ratingAvg ratingCount avatarPath')
            .skip(skip).limit(limit)
            .sort({ appliedAt: -1 }),
        Application.countDocuments(filter),
    ]);

    return { applications, pagination: paginationMeta(total, page, limit) };
};

/**
 * Get application by ID.
 */
const getApplicationById = async (id) => {
    const application = await Application.findById(id)
        .populate('userId', 'name email phone ratingAvg avatarPath')
        .populate({
            path: 'eventId',
            select: 'title startTime endTime status companyId',
            populate: { path: 'companyId', select: 'name owner' },
        });
    if (!application) throw new AppError('Application not found', 404);
    return application;
};

/**
 * Update application status (company/team_leader).
 */
const updateApplicationStatus = async (applicationId, newStatus, actorId) => {
    const application = await Application.findById(applicationId)
        .populate('userId', 'name email')
        .populate('eventId', 'title companyId');
    if (!application) throw new AppError('Application not found', 404);

    const oldStatus = application.status;
    application.status = newStatus;
    await application.save();

    // Create notification for the applicant
    const statusMessages = {
        shortlisted: 'Your application has been shortlisted!',
        invited: 'You have been invited!',
        accepted: 'Congratulations! Your application has been accepted!',
        rejected: 'Unfortunately, your application was not successful.',
        declined: 'Your application has been declined.',
    };

    if (statusMessages[newStatus]) {
        await Notification.create({
            userId: application.userId._id,
            type: 'application_status',
            relatedId: application._id,
            title: `Application ${newStatus}`,
            message: `${statusMessages[newStatus]} Event: ${application.eventId.title}`,
        });
    }

    return application;
};

/**
 * Withdraw application (user).
 */
const withdrawApplication = async (applicationId, userId) => {
    const application = await Application.findById(applicationId);
    if (!application) throw new AppError('Application not found', 404);
    if (application.userId.toString() !== userId) {
        throw new AppError('Not authorized to withdraw this application', 403);
    }
    if (['accepted', 'rejected'].includes(application.status)) {
        throw new AppError(`Cannot withdraw application with status '${application.status}'`, 400);
    }

    await Application.findByIdAndDelete(applicationId);
};

/**
 * Get all applications (admin view).
 */
const getAllApplications = async (query) => {
    const { skip, limit, page } = parsePagination(query);
    const filter = {};
    if (query.status) filter.status = query.status;

    const [applications, total] = await Promise.all([
        Application.find(filter)
            .populate('userId', 'name email phone avatarPath')
            .populate({
                path: 'eventId',
                select: 'title startTime status companyId',
                populate: { path: 'companyId', select: 'name' },
            })
            .skip(skip).limit(limit)
            .sort({ appliedAt: -1 }),
        Application.countDocuments(filter),
    ]);

    return { applications, pagination: paginationMeta(total, page, limit) };
};

/**
 * Get application count by status (admin).
 */
const getApplicationStatsByStatus = async () => {
    const stats = await Application.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);
    const result = {};
    stats.forEach((s) => { result[s._id] = s.count; });
    return result;
};

module.exports = {
    applyToEvent,
    getUserApplications,
    getAllApplications,
    getEventApplications,
    getApplicationById,
    updateApplicationStatus,
    withdrawApplication,
    getApplicationStatsByStatus,
};
