const Notification = require('../models/Notification');
const { parsePagination, paginationMeta } = require('../utils/pagination');

const getUserNotifications = async (userId, query) => {
    const { skip, limit, page } = parsePagination(query);

    const [notifications, total] = await Promise.all([
        Notification.find({ userId }).skip(skip).limit(limit).sort({ createdAt: -1 }),
        Notification.countDocuments({ userId }),
    ]);

    return { notifications, pagination: paginationMeta(total, page, limit) };
};

const getUnreadCount = async (userId) => {
    return Notification.countDocuments({ userId, isRead: false });
};

const markAsRead = async (notificationId, userId) => {
    const notification = await Notification.findOneAndUpdate(
        { _id: notificationId, userId },
        { isRead: true },
        { new: true }
    );
    return notification;
};

const markAllAsRead = async (userId) => {
    await Notification.updateMany({ userId, isRead: false }, { isRead: true });
};

/**
 * Create a notification (internal use — called by other services).
 */
const createNotification = async (data) => {
    return Notification.create(data);
};

module.exports = {
    getUserNotifications,
    getUnreadCount,
    markAsRead,
    markAllAsRead,
    createNotification,
};
