const Joi = require('joi');

const createNotification = Joi.object({
    userId: Joi.string().required(),
    type: Joi.string()
        .valid('invite', 'accepted', 'declined', 'message', 'rating', 'application_status', 'event_approved', 'event_rejected')
        .default('message'),
    relatedId: Joi.string().allow(null),
    title: Joi.string().max(255).required(),
    message: Joi.string().max(2000).allow('', null),
});

module.exports = { createNotification };
