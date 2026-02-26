const asyncHandler = require('../utils/asyncHandler');
const auditLogService = require('../services/auditLog.service');

exports.getAuditLogs = asyncHandler(async (req, res) => {
    const result = await auditLogService.getAuditLogs(req.query);
    res.json({ success: true, data: result });
});
