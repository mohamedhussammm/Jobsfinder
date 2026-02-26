const mongoose = require('mongoose');

const applicationSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Application must belong to a user'],
        },
        eventId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Event',
            required: [true, 'Application must reference an event'],
        },
        status: {
            type: String,
            enum: ['applied', 'shortlisted', 'invited', 'accepted', 'declined', 'rejected'],
            default: 'applied',
        },
        cvPath: {
            type: String,
        },
        coverLetter: {
            type: String,
            trim: true,
        },
        experience: {
            type: String,
            trim: true,
        },
        isAvailable: {
            type: Boolean,
            default: false,
        },
        openToOtherOptions: {
            type: Boolean,
            default: false,
        },
        appliedAt: {
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

// One application per user per event
applicationSchema.index({ userId: 1, eventId: 1 }, { unique: true });
applicationSchema.index({ eventId: 1 });
applicationSchema.index({ userId: 1 });
applicationSchema.index({ status: 1 });

module.exports = mongoose.model('Application', applicationSchema);
