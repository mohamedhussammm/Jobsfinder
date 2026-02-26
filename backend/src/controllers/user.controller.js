const asyncHandler = require('../utils/asyncHandler');
const userService = require('../services/user.service');
const auditLogService = require('../services/auditLog.service');

exports.getAllUsers = asyncHandler(async (req, res) => {
    const result = await userService.getAllUsers(req.query);
    res.json({ success: true, data: result });
});

exports.getUserById = asyncHandler(async (req, res) => {
    const userId = req.params.id;
    const requesterId = req.user._id;
    const requesterRole = req.user.role;

    // Admin can see everything
    if (requesterRole === 'admin') {
        const user = await userService.getUserById(userId);
        return res.json({ success: true, data: { user } });
    }

    // Own profile
    if (userId === requesterId.toString()) {
        const user = await userService.getUserById(userId);
        return res.json({ success: true, data: { user } });
    }

    // Team Leader access check
    if (requesterRole === 'team_leader') {
        const TeamLeader = require('../models/TeamLeader');
        const Application = require('../models/Application');

        // 1. Get events managed by this TL
        const myAssignments = await TeamLeader.find({
            userId: requesterId,
            status: { $ne: 'removed' }
        });
        const myEventIds = myAssignments.map(a => a.eventId);

        // 2. See if the target user applied to any of these events
        const application = await Application.findOne({
            userId: userId,
            eventId: { $in: myEventIds }
        });

        if (application) {
            const user = await userService.getUserById(userId);
            return res.json({ success: true, data: { user } });
        }
    }

    // Default restricted access or 403
    // For now, let's keep it restricted to authorized personnel
    res.status(403).json({
        success: false,
        message: 'You are not authorized to view this profile'
    });
});

exports.updateProfile = asyncHandler(async (req, res) => {
    const user = await userService.updateProfile(req.user._id, req.body);
    res.json({ success: true, data: { user } });
});

exports.blockUser = asyncHandler(async (req, res) => {
    const user = await userService.blockUser(req.params.id);
    await auditLogService.createLog({
        adminUserId: req.user._id,
        action: 'user_blocked',
        targetTable: 'users',
        targetId: user._id,
        oldValues: { deletedAt: null },
        newValues: { deletedAt: user.deletedAt },
        ipAddress: req.ip,
    });
    res.json({ success: true, data: { user }, message: 'User blocked' });
});

exports.unblockUser = asyncHandler(async (req, res) => {
    const user = await userService.unblockUser(req.params.id);
    await auditLogService.createLog({
        adminUserId: req.user._id,
        action: 'user_unblocked',
        targetTable: 'users',
        targetId: user._id,
        oldValues: { deletedAt: user.deletedAt },
        newValues: { deletedAt: null },
        ipAddress: req.ip,
    });
    res.json({ success: true, data: { user }, message: 'User unblocked' });
});

exports.changeRole = asyncHandler(async (req, res) => {
    const user = await userService.changeRole(req.params.id, req.body.role);
    await auditLogService.createLog({
        adminUserId: req.user._id,
        action: 'user_role_changed',
        targetTable: 'users',
        targetId: user._id,
        newValues: { role: user.role },
        ipAddress: req.ip,
    });
    res.json({ success: true, data: { user }, message: 'Role updated' });
});
