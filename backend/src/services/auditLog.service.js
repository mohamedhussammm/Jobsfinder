const AuditLog = require('../models/AuditLog');
const { parsePagination, paginationMeta } = require('../utils/pagination');

/**
 * Create an audit log entry. Called internally by other services.
 */
const createLog = async ({ adminUserId, action, targetTable, targetId, oldValues, newValues, ipAddress }) => {
    return AuditLog.create({
        adminUserId,
        action,
        targetTable,
        targetId,
        oldValues,
        newValues,
        ipAddress,
    });
};

/**
 * Get audit logs with filtering (admin).
 */
const getAuditLogs = async (query) => {
    const { skip, limit, page } = parsePagination(query);
    const filter = {};

    if (query.adminUserId) filter.adminUserId = query.adminUserId;
    if (query.targetTable) filter.targetTable = query.targetTable;
    if (query.action) filter.action = { $regex: query.action, $options: 'i' };

    const [logs, total] = await Promise.all([
        AuditLog.find(filter)
            .populate('adminUserId', 'name email')
            .skip(skip).limit(limit)
            .sort({ createdAt: -1 }),
        AuditLog.countDocuments(filter),
    ]);

    return { logs, pagination: paginationMeta(total, page, limit) };
};

module.exports = { createLog, getAuditLogs };
