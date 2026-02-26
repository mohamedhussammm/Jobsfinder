const express = require('express');
const router = express.Router();
const ratingController = require('../controllers/rating.controller');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { createRating } = require('../validations/rating.validation');

router.use(protect);

router.post('/', authorize('team_leader', 'company'), validate(createRating), ratingController.createRating);
router.get('/given', ratingController.getMyGivenRatings);
router.get('/user/:userId', ratingController.getUserRatings);
router.get('/event/:eventId', ratingController.getEventRatings);

module.exports = router;
