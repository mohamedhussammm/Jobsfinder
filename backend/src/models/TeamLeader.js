const mongoose = require('mongoose');

const teamLeaderSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Team leader assignment must reference a user'],
        },
        eventId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Event',
            required: [true, 'Team leader assignment must reference an event'],
        },
        assignedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        status: {
            type: String,
            enum: ['assigned', 'active', 'completed', 'removed'],
            default: 'assigned',
        },
        assignedAt: {
            type: Date,
            default: Date.now,
        },
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

// One assignment per leader per event
teamLeaderSchema.index({ userId: 1, eventId: 1 }, { unique: true });
teamLeaderSchema.index({ eventId: 1 });
teamLeaderSchema.index({ userId: 1 });
teamLeaderSchema.index({ status: 1 });

module.exports = mongoose.model('TeamLeader', teamLeaderSchema);
