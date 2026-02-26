const asyncHandler = require('../utils/asyncHandler');
const eventService = require('../services/event.service');
const notificationService = require('../services/notification.service');
const auditLogService = require('../services/auditLog.service');

exports.createEvent = asyncHandler(async (req, res) => {
    const event = await eventService.createEvent(req.user._id.toString(), req.user.role, req.body);
    res.status(201).json({ success: true, data: { event } });
});

exports.getPublishedEvents = asyncHandler(async (req, res) => {
    const result = await eventService.getPublishedEvents(req.query);
    res.json({ success: true, data: result });
});

exports.getEventById = asyncHandler(async (req, res) => {
    const event = await eventService.getEventById(req.params.id);
    res.json({ success: true, data: { event } });
});

exports.getPendingEvents = asyncHandler(async (req, res) => {
    const result = await eventService.getPendingEvents(req.query);
    res.json({ success: true, data: result });
});

exports.getCompanyEvents = asyncHandler(async (req, res) => {
    const result = await eventService.getCompanyEvents(req.params.companyId, req.query);
    res.json({ success: true, data: result });
});

exports.updateEvent = asyncHandler(async (req, res) => {
    const event = await eventService.updateEvent(
        req.params.id, req.user._id.toString(), req.user.role, req.body
    );
    res.json({ success: true, data: { event } });
});

exports.approveEvent = asyncHandler(async (req, res) => {
    const event = await eventService.approveEvent(req.params.id);

    // Notify the company
    const fullEvent = await eventService.getEventById(req.params.id);
    if (fullEvent.companyId && fullEvent.companyId.owner) {
        await notificationService.createNotification({
            userId: fullEvent.companyId.owner,
            type: 'event_approved',
            relatedId: event._id,
            title: 'Event Approved',
            message: `Your event "${event.title}" has been approved and is now published.`,
        });
    }

    await auditLogService.createLog({
        adminUserId: req.user._id,
        action: 'event_approved',
        targetTable: 'events',
        targetId: event._id,
        oldValues: { status: 'pending' },
        newValues: { status: 'published' },
        ipAddress: req.ip,
    });

    res.json({ success: true, data: { event }, message: 'Event approved' });
});

exports.rejectEvent = asyncHandler(async (req, res) => {
    const event = await eventService.rejectEvent(req.params.id, req.body.reason);

    // Notify the company
    const fullEvent = await eventService.getEventById(req.params.id);
    if (fullEvent.companyId && fullEvent.companyId.owner) {
        await notificationService.createNotification({
            userId: fullEvent.companyId.owner,
            type: 'event_rejected',
            relatedId: event._id,
            title: 'Event Rejected',
            message: `Your event "${event.title}" was rejected. ${req.body.reason ? 'Reason: ' + req.body.reason : ''}`,
        });
    }

    await auditLogService.createLog({
        adminUserId: req.user._id,
        action: 'event_rejected',
        targetTable: 'events',
        targetId: event._id,
        oldValues: { status: 'pending' },
        newValues: { status: 'cancelled', rejectionReason: req.body.reason },
        ipAddress: req.ip,
    });

    res.json({ success: true, data: { event }, message: 'Event rejected' });
});

exports.searchEvents = asyncHandler(async (req, res) => {
    const result = await eventService.searchEvents(req.query);
    res.json({ success: true, data: result });
});
exports.deleteEvent = asyncHandler(async (req, res) => {
    await eventService.deleteEvent(req.params.id);

    await auditLogService.createLog({
        adminUserId: req.user._id,
        action: 'event_deleted',
        targetTable: 'events',
        targetId: req.params.id,
        ipAddress: req.ip,
    });

    res.json({ success: true, message: 'Event deleted' });
});
