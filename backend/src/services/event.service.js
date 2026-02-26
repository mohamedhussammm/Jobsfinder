const Event = require('../models/Event');
const Company = require('../models/Company');
const AppError = require('../utils/AppError');
const { parsePagination, paginationMeta } = require('../utils/pagination');

/**
 * Create event — companies start as 'pending', admins can set status directly.
 */
const createEvent = async (userId, userRole, data) => {
    // Verify the company exists
    const company = await Company.findById(data.companyId);
    if (!company) throw new AppError('Company not found', 404);
    if (userRole !== 'admin' && company.owner.toString() !== userId) {
        throw new AppError('You can only create events for your own company', 403);
    }

    // Admins can set status directly (e.g. 'published'); companies always start as 'pending'
    const status = userRole === 'admin' ? (data.status || 'published') : 'pending';

    const event = await Event.create({ ...data, status });
    return event;
};

/**
 * Get published events (public).
 */
const getPublishedEvents = async (query) => {
    const { skip, limit, page } = parsePagination(query);
    const filter = { status: 'published' };

    if (query.search) {
        filter.title = { $regex: query.search, $options: 'i' };
    }
    if (query.category) {
        filter.categoryId = query.category;
    }

    const [events, total] = await Promise.all([
        Event.find(filter)
            .populate('companyId', 'name logoPath verified')
            .populate('categoryId', 'name icon')
            .skip(skip).limit(limit)
            .sort({ startTime: 1 }),
        Event.countDocuments(filter),
    ]);

    return { events, pagination: paginationMeta(total, page, limit) };
};

/**
 * Get event by ID.
 */
const getEventById = async (id) => {
    const event = await Event.findById(id)
        .populate('companyId', 'name logoPath verified owner')
        .populate('categoryId', 'name icon');
    if (!event) throw new AppError('Event not found', 404);
    return event;
};

/**
 * Get pending events (admin).
 */
const getPendingEvents = async (query) => {
    const { skip, limit, page } = parsePagination(query);
    const filter = { status: 'pending' };

    const [events, total] = await Promise.all([
        Event.find(filter)
            .populate('companyId', 'name logoPath')
            .skip(skip).limit(limit)
            .sort({ createdAt: 1 }),
        Event.countDocuments(filter),
    ]);

    return { events, pagination: paginationMeta(total, page, limit) };
};

/**
 * Get company's own events.
 */
const getCompanyEvents = async (companyId, query) => {
    const { skip, limit, page } = parsePagination(query);
    const filter = { companyId };

    const [events, total] = await Promise.all([
        Event.find(filter)
            .populate('categoryId', 'name icon')
            .skip(skip).limit(limit)
            .sort({ createdAt: -1 }),
        Event.countDocuments(filter),
    ]);

    return { events, pagination: paginationMeta(total, page, limit) };
};

/**
 * Update event (company owner only, and only certain fields).
 */
const updateEvent = async (eventId, userId, userRole, data) => {
    const event = await Event.findById(eventId).populate('companyId', 'owner');
    if (!event) throw new AppError('Event not found', 404);

    // Only the owning company or admin can update
    if (userRole !== 'admin' && event.companyId.owner.toString() !== userId) {
        throw new AppError('Not authorized to update this event', 403);
    }

    // Companies cannot change status directly
    if (userRole !== 'admin') {
        delete data.status;
    }

    Object.assign(event, data);
    await event.save();
    return event;
};

/**
 * Approve event (admin only) — sets status to 'published'.
 */
const approveEvent = async (eventId) => {
    const event = await Event.findById(eventId);
    if (!event) throw new AppError('Event not found', 404);
    if (event.status !== 'pending') {
        throw new AppError(`Cannot approve event with status '${event.status}'`, 400);
    }

    event.status = 'published';
    await event.save();
    return event;
};

/**
 * Reject event (admin only) — sets status to 'cancelled'.
 */
const rejectEvent = async (eventId, reason) => {
    const event = await Event.findById(eventId);
    if (!event) throw new AppError('Event not found', 404);
    if (event.status !== 'pending') {
        throw new AppError(`Cannot reject event with status '${event.status}'`, 400);
    }

    event.status = 'cancelled';
    event.rejectionReason = reason || '';
    await event.save();
    return event;
};

/**
 * Search events.
 */
const searchEvents = async (query) => {
    const { skip, limit, page } = parsePagination(query);
    const filter = {
        status: 'published',
        title: { $regex: query.q || '', $options: 'i' },
    };

    const [events, total] = await Promise.all([
        Event.find(filter)
            .populate('companyId', 'name logoPath')
            .populate('categoryId', 'name icon')
            .skip(skip).limit(limit)
            .sort({ startTime: 1 }),
        Event.countDocuments(filter),
    ]);

    return { events, pagination: paginationMeta(total, page, limit) };
};

/**
 * Get event statistics (admin).
 */
const getEventStatistics = async () => {
    const stats = await Event.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);
    const result = {};
    stats.forEach((s) => { result[s._id] = s.count; });
    return result;
};

/**
 * Delete event (admin only).
 */
const deleteEvent = async (eventId) => {
    const event = await Event.findByIdAndDelete(eventId);
    if (!event) throw new AppError('Event not found', 404);
    return event;
};

module.exports = {
    createEvent,
    getPublishedEvents,
    getEventById,
    getPendingEvents,
    getCompanyEvents,
    updateEvent,
    approveEvent,
    rejectEvent,
    searchEvents,
    getEventStatistics,
    deleteEvent,
};
