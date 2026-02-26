const TeamLeader = require('../models/TeamLeader');
const User = require('../models/User');
const Event = require('../models/Event');
const AppError = require('../utils/AppError');

const assignTeamLeader = async (userId, eventId, assignedBy) => {
    // Verify user exists and has team_leader role
    const user = await User.findById(userId);
    if (!user) throw new AppError('User not found', 404);
    if (user.role !== 'team_leader') {
        throw new AppError('User must have team_leader role', 400);
    }

    // Verify event exists
    const event = await Event.findById(eventId);
    if (!event) throw new AppError('Event not found', 404);

    try {
        const assignment = await TeamLeader.create({
            userId,
            eventId,
            assignedBy,
            status: 'assigned',
        });
        return assignment;
    } catch (err) {
        if (err.code === 11000) {
            throw new AppError('Team leader already assigned to this event', 400);
        }
        throw err;
    }
};

const getTeamLeadersForEvent = async (eventId) => {
    return TeamLeader.find({ eventId, status: { $ne: 'removed' } })
        .populate('userId', 'name email phone avatarPath')
        .populate('assignedBy', 'name')
        .sort({ assignedAt: -1 });
};

const getTeamLeaderEvents = async (userId) => {
    const assignments = await TeamLeader.find({
        userId,
        status: { $ne: 'removed' },
    }).populate({
        path: 'eventId',
        populate: { path: 'companyId', select: 'name logoPath' },
    });

    const Application = require('../models/Application');

    // Add applicant counts to each assignment's event
    const results = await Promise.all(assignments.map(async (assignment) => {
        if (assignment.eventId) {
            const count = await Application.countDocuments({ eventId: assignment.eventId._id });
            // We convert to JSON to add the field
            const assignmentObj = assignment.toJSON();
            if (assignmentObj.eventId) {
                assignmentObj.eventId.applicantsCount = count;
            }
            return assignmentObj;
        }
        return assignment;
    }));

    return results;
};

const updateAssignmentStatus = async (assignmentId, newStatus) => {
    const assignment = await TeamLeader.findByIdAndUpdate(
        assignmentId,
        { status: newStatus },
        { new: true, runValidators: true }
    );
    if (!assignment) throw new AppError('Assignment not found', 404);
    return assignment;
};

const removeTeamLeader = async (assignmentId) => {
    const assignment = await TeamLeader.findByIdAndUpdate(
        assignmentId,
        { status: 'removed' },
        { new: true }
    );
    if (!assignment) throw new AppError('Assignment not found', 404);
    return assignment;
};

const isTeamLeaderForEvent = async (userId, eventId) => {
    const assignment = await TeamLeader.findOne({
        userId,
        eventId,
        status: { $ne: 'removed' },
    });
    return !!assignment;
};

module.exports = {
    assignTeamLeader,
    getTeamLeadersForEvent,
    getTeamLeaderEvents,
    updateAssignmentStatus,
    removeTeamLeader,
    isTeamLeaderForEvent,
};
