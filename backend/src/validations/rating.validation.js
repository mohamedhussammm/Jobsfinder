const Joi = require('joi');

const createRating = Joi.object({
    ratedUserId: Joi.string().required(),
    eventId: Joi.string().required(),
    score: Joi.number().integer().min(1).max(5).required(),
    textReview: Joi.string().max(2000).allow('', null),
});

module.exports = { createRating };
