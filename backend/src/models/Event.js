const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema(
    {
        companyId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Company',
            required: [true, 'Event must belong to a company'],
        },
        title: {
            type: String,
            required: [true, 'Event title is required'],
            trim: true,
        },
        description: {
            type: String,
            trim: true,
        },
        location: {
            address: { type: String },
            lat: { type: Number },
            lng: { type: Number },
        },
        startTime: {
            type: Date,
            required: [true, 'Start time is required'],
        },
        endTime: {
            type: Date,
            required: [true, 'End time is required'],
        },
        capacity: {
            type: Number,
            min: [1, 'Capacity must be at least 1'],
        },
        imagePath: {
            type: String,
        },
        status: {
            type: String,
            enum: ['draft', 'pending', 'published', 'completed', 'cancelled'],
            default: 'pending',
        },
        categoryId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Category',
        },
        rejectionReason: {
            type: String,
        },

        // ─── New fields ─────────────────────────────
        salary: {
            type: Number,
            min: [0, 'Salary cannot be negative'],
        },
        requirements: {
            type: String,
            trim: true,
        },
        benefits: {
            type: String,
            trim: true,
        },
        contactEmail: {
            type: String,
            trim: true,
            lowercase: true,
        },
        contactPhone: {
            type: String,
            trim: true,
        },
        tags: {
            type: [String],
            default: [],
        },
        isUrgent: {
            type: Boolean,
            default: false,
        },
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

// ─── Indexes ────────────────────────────────────
eventSchema.index({ status: 1 });
eventSchema.index({ companyId: 1 });
eventSchema.index({ startTime: 1 });
eventSchema.index({ categoryId: 1 });
eventSchema.index({ tags: 1 });

// ─── Validation: endTime must be after startTime ─
eventSchema.pre('validate', function (next) {
    if (this.startTime && this.endTime && this.endTime <= this.startTime) {
        this.invalidate('endTime', 'End time must be after start time');
    }
    next();
});

// ─── Virtual: application count ─────────────────
eventSchema.virtual('applications', {
    ref: 'Application',
    localField: '_id',
    foreignField: 'eventId',
    count: true,
});

module.exports = mongoose.model('Event', eventSchema);
