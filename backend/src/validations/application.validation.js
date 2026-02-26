const Joi = require('joi');

const applyToEvent = Joi.object({
    eventId: Joi.string().required(),
    coverLetter: Joi.string().max(5000).allow('', null),
});

const updateApplicationStatus = Joi.object({
    status: Joi.string()
        .valid('applied', 'shortlisted', 'invited', 'accepted', 'declined', 'rejected')
        .required(),
});

module.exports = { applyToEvent, updateApplicationStatus };
