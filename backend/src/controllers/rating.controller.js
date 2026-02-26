const asyncHandler = require('../utils/asyncHandler');
const ratingService = require('../services/rating.service');

exports.createRating = asyncHandler(async (req, res) => {
    const rating = await ratingService.createRating(req.user._id, req.body);
    res.status(201).json({ success: true, data: { rating } });
});

exports.getUserRatings = asyncHandler(async (req, res) => {
    const ratings = await ratingService.getUserRatings(req.params.userId);
    res.json({ success: true, data: { ratings } });
});

exports.getEventRatings = asyncHandler(async (req, res) => {
    const ratings = await ratingService.getEventRatings(req.params.eventId);
    res.json({ success: true, data: { ratings } });
});

exports.getMyGivenRatings = asyncHandler(async (req, res) => {
    const ratings = await ratingService.getRatingsGivenByUser(req.user._id);
    res.json({ success: true, data: { ratings } });
});
