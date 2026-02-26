const AppError = require('../utils/AppError');

/**
 * Joi validation middleware factory.
 * @param {import('joi').ObjectSchema} schema - Joi schema to validate req.body
 */
const validate = (schema) => (req, _res, next) => {
    const { error, value } = schema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
    });

    if (error) {
        const messages = error.details.map((d) => d.message).join(', ');
        return next(new AppError(messages, 400));
    }

    // Replace body with validated (and stripped) value
    req.body = value;
    next();
};

module.exports = validate;
