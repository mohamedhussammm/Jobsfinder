const Joi = require('joi');

const updateProfile = Joi.object({
    name: Joi.string().min(2).max(100),
    phone: Joi.string().max(20).allow('', null),
    avatarPath: Joi.string().allow('', null),
    profileComplete: Joi.boolean(),
}).min(1);

const updateUserRole = Joi.object({
    role: Joi.string().valid('normal', 'company', 'team_leader', 'admin').required(),
});

module.exports = { updateProfile, updateUserRole };
