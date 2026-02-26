const AppError = require('../utils/AppError');
const logger = require('../utils/logger');

const errorHandler = (err, req, res, _next) => {
    err.statusCode = err.statusCode || 500;
    err.status = err.status || 'error';

    // Mongoose bad ObjectId
    if (err.name === 'CastError') {
        err = new AppError(`Invalid ${err.path}: ${err.value}`, 400);
    }

    // Mongoose duplicate key
    if (err.code === 11000) {
        const field = Object.keys(err.keyValue).join(', ');
        err = new AppError(`Duplicate value for field: ${field}. Please use another value.`, 400);
    }

    // Mongoose validation error
    if (err.name === 'ValidationError') {
        const messages = Object.values(err.errors).map((e) => e.message);
        err = new AppError(`Validation Error: ${messages.join('. ')}`, 400);
    }

    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        err = new AppError('Invalid token. Please log in again.', 401);
    }
    if (err.name === 'TokenExpiredError') {
        err = new AppError('Token expired. Please log in again.', 401);
    }

    // Log error in development
    if (process.env.NODE_ENV === 'development') {
        logger.error(err.message, err.stack);
    } else {
        if (!err.isOperational) {
            logger.error('UNEXPECTED ERROR:', err);
        }
    }

    res.status(err.statusCode).json({
        success: false,
        status: err.status,
        message: err.isOperational ? err.message : 'Something went wrong',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    });
};

module.exports = errorHandler;
