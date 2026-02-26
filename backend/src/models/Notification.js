const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Notification must belong to a user'],
        },
        type: {
            type: String,
            enum: ['invite', 'accepted', 'declined', 'message', 'rating', 'application_status', 'event_approved', 'event_rejected'],
            default: 'message',
        },
        relatedId: {
            type: mongoose.Schema.Types.ObjectId,
        },
        title: {
            type: String,
            trim: true,
        },
        message: {
            type: String,
            trim: true,
        },
        isRead: {
            type: Boolean,
            default: false,
        },
    },
    {
        timestamps: true,
    }
);

notificationSchema.index({ userId: 1 });
notificationSchema.index({ isRead: 1 });
notificationSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
