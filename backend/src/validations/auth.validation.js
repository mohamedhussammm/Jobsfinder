const Joi = require('joi');

const register = Joi.object({
    email: Joi.string().email().required().messages({
        'string.email': 'Please provide a valid email',
        'any.required': 'Email is required',
    }),
    password: Joi.string().min(8).max(128).required().messages({
        'string.min': 'Password must be at least 8 characters',
        'any.required': 'Password is required',
    }),
    name: Joi.string().min(2).max(100).required().messages({
        'any.required': 'Name is required',
    }),
    nationalIdNumber: Joi.string().min(5).max(50).required().messages({
        'any.required': 'National ID number is required',
    }),
    role: Joi.string().valid('normal', 'company', 'team_leader').default('normal'),
    phone: Joi.string().max(20).allow('', null),
});

const login = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required(),
});

const refreshToken = Joi.object({
    refreshToken: Joi.string().required(),
});

const forgotPassword = Joi.object({
    email: Joi.string().email().required(),
});

const resetPassword = Joi.object({
    password: Joi.string().min(8).max(128).required(),
});

module.exports = {
    register,
    login,
    refreshToken,
    forgotPassword,
    resetPassword,
};
