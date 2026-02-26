const Joi = require('joi');

const createCompany = Joi.object({
    name: Joi.string().min(2).max(255).required(),
    description: Joi.string().max(2000).allow('', null),
});

const updateCompany = Joi.object({
    name: Joi.string().min(2).max(255),
    description: Joi.string().max(2000).allow('', null),
}).min(1);

module.exports = { createCompany, updateCompany };
