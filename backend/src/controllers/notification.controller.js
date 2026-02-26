const asyncHandler = require('../utils/asyncHandler');
const notificationService = require('../services/notification.service');

exports.getMyNotifications = asyncHandler(async (req, res) => {
    const result = await notificationService.getUserNotifications(req.user._id, req.query);
    res.json({ success: true, data: result });
});

exports.getUnreadCount = asyncHandler(async (req, res) => {
    const count = await notificationService.getUnreadCount(req.user._id);
    res.json({ success: true, data: { count } });
});

exports.markAsRead = asyncHandler(async (req, res) => {
    const notification = await notificationService.markAsRead(req.params.id, req.user._id);
    res.json({ success: true, data: { notification } });
});

exports.markAllAsRead = asyncHandler(async (req, res) => {
    await notificationService.markAllAsRead(req.user._id);
    res.json({ success: true, message: 'All notifications marked as read' });
});
