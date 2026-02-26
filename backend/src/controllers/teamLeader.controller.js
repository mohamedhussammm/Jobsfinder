const asyncHandler = require('../utils/asyncHandler');
const teamLeaderService = require('../services/teamLeader.service');
const auditLogService = require('../services/auditLog.service');

exports.assignTeamLeader = asyncHandler(async (req, res) => {
    const assignment = await teamLeaderService.assignTeamLeader(
        req.body.userId, req.body.eventId, req.user._id
    );
    await auditLogService.createLog({
        adminUserId: req.user._id,
        action: 'team_leader_assigned',
        targetTable: 'team_leaders',
        targetId: assignment._id,
        newValues: { userId: req.body.userId, eventId: req.body.eventId },
        ipAddress: req.ip,
    });
    res.status(201).json({ success: true, data: { assignment } });
});

exports.getTeamLeadersForEvent = asyncHandler(async (req, res) => {
    const leaders = await teamLeaderService.getTeamLeadersForEvent(req.params.eventId);
    res.json({ success: true, data: { leaders } });
});

exports.getMyEvents = asyncHandler(async (req, res) => {
    const assignments = await teamLeaderService.getTeamLeaderEvents(req.user._id);
    res.json({ success: true, data: { assignments } });
});

exports.updateAssignmentStatus = asyncHandler(async (req, res) => {
    const assignment = await teamLeaderService.updateAssignmentStatus(
        req.params.id, req.body.status
    );
    res.json({ success: true, data: { assignment } });
});

exports.removeTeamLeader = asyncHandler(async (req, res) => {
    const assignment = await teamLeaderService.removeTeamLeader(req.params.id);
    await auditLogService.createLog({
        adminUserId: req.user._id,
        action: 'team_leader_removed',
        targetTable: 'team_leaders',
        targetId: assignment._id,
        newValues: { status: 'removed' },
        ipAddress: req.ip,
    });
    res.json({ success: true, message: 'Team leader removed' });
});
