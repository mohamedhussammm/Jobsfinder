const express = require('express');
const router = express.Router();
const teamLeaderController = require('../controllers/teamLeader.controller');
const { protect, authorize } = require('../middleware/auth');

router.use(protect);

router.post('/', authorize('company', 'admin'), teamLeaderController.assignTeamLeader);
router.get('/my-events', authorize('team_leader'), teamLeaderController.getMyEvents);
router.get('/event/:eventId', teamLeaderController.getTeamLeadersForEvent);
router.patch('/:id/status', authorize('team_leader', 'admin'), teamLeaderController.updateAssignmentStatus);
router.delete('/:id', authorize('admin'), teamLeaderController.removeTeamLeader);

module.exports = router;
