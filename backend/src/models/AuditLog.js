const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
    {
        adminUserId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        action: {
            type: String,
            required: [true, 'Action is required'],
            trim: true,
        },
        targetTable: {
            type: String,
            trim: true,
        },
        targetId: {
            type: mongoose.Schema.Types.ObjectId,
        },
        oldValues: {
            type: mongoose.Schema.Types.Mixed,
        },
        newValues: {
            type: mongoose.Schema.Types.Mixed,
        },
        ipAddress: {
            type: String,
        },
    },
    {
        timestamps: true,
    }
);

auditLogSchema.index({ adminUserId: 1 });
auditLogSchema.index({ targetTable: 1, targetId: 1 });
auditLogSchema.index({ createdAt: -1 });

module.exports = mongoose.model('AuditLog', auditLogSchema);
