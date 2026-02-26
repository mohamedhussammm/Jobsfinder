const mongoose = require('mongoose');

const companySchema = new mongoose.Schema(
    {
        owner: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Company must have an owner'],
        },
        name: {
            type: String,
            required: [true, 'Company name is required'],
            trim: true,
        },
        description: {
            type: String,
            trim: true,
        },
        logoPath: {
            type: String,
        },
        verified: {
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

companySchema.index({ name: 1 });
companySchema.index({ owner: 1 });

module.exports = mongoose.model('Company', companySchema);
