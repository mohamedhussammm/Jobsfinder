const express = require('express');
const router = express.Router();
const applicationController = require('../controllers/application.controller');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { applyToEvent, updateApplicationStatus } = require('../validations/application.validation');

router.use(protect);

router.get('/', authorize('admin'), applicationController.getAllApplications);
router.post('/', authorize('normal'), validate(applyToEvent), applicationController.applyToEvent);
router.get('/my', applicationController.getMyApplications);
router.get('/stats', authorize('admin'), applicationController.getApplicationStats);
router.get('/event/:eventId', authorize('company', 'team_leader', 'admin'), applicationController.getEventApplications);
router.get('/:id', applicationController.getApplicationById);
router.patch(
    '/:id/status',
    authorize('company', 'team_leader', 'admin'),
    validate(updateApplicationStatus),
    applicationController.updateApplicationStatus
);
router.delete('/:id', authorize('normal'), applicationController.withdrawApplication);

module.exports = router;
