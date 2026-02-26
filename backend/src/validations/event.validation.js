const Joi = require('joi');

const createEvent = Joi.object({
    companyId: Joi.string().required(),
    title: Joi.string().min(3).max(255).required(),
    description: Joi.string().max(5000).allow('', null),
    location: Joi.object({
        address: Joi.string().allow('', null),
        lat: Joi.number().min(-90).max(90).allow(null),
        lng: Joi.number().min(-180).max(180).allow(null),
    }).allow(null),
    startTime: Joi.date().iso().required(),
    endTime: Joi.date().iso().greater(Joi.ref('startTime')).required().messages({
        'date.greater': 'End time must be after start time',
    }),
    capacity: Joi.number().integer().min(1).allow(null),
    categoryId: Joi.string().allow('', null),
    // New fields
    salary: Joi.number().min(0).allow(null),
    requirements: Joi.string().max(5000).allow('', null),
    benefits: Joi.string().max(5000).allow('', null),
    contactEmail: Joi.string().email().allow('', null),
    contactPhone: Joi.string().max(20).allow('', null),
    tags: Joi.array().items(Joi.string().max(50)).max(10).allow(null),
    isUrgent: Joi.boolean().allow(null),
    status: Joi.string().valid('draft', 'pending', 'published').allow(null),
});

const updateEvent = Joi.object({
    title: Joi.string().min(3).max(255),
    description: Joi.string().max(5000).allow('', null),
    location: Joi.object({
        address: Joi.string().allow('', null),
        lat: Joi.number().min(-90).max(90).allow(null),
        lng: Joi.number().min(-180).max(180).allow(null),
    }),
    startTime: Joi.date().iso(),
    endTime: Joi.date().iso(),
    capacity: Joi.number().integer().min(1),
    categoryId: Joi.string().allow('', null),
    salary: Joi.number().min(0).allow(null),
    requirements: Joi.string().max(5000).allow('', null),
    benefits: Joi.string().max(5000).allow('', null),
    contactEmail: Joi.string().email().allow('', null),
    contactPhone: Joi.string().max(20).allow('', null),
    tags: Joi.array().items(Joi.string().max(50)).max(10).allow(null),
    isUrgent: Joi.boolean().allow(null),
}).min(1);

const rejectEvent = Joi.object({
    reason: Joi.string().max(1000).allow('', null),
});

module.exports = { createEvent, updateEvent, rejectEvent };
