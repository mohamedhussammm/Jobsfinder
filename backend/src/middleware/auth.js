const { verifyAccessToken } = require('../utils/tokens');
const User = require('../models/User');
const AppError = require('../utils/AppError');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Protect routes — verifies JWT access token from Authorization header.
 * Attaches the full user document to req.user.
 */
const protect = asyncHandler(async (req, _res, next) => {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
        return next(new AppError('Not authorized. No token provided.', 401));
    }

    // Verify token
    const decoded = verifyAccessToken(token);

    // Check if user still exists and is not blocked
    const user = await User.findById(decoded.id).select('-password');
    if (!user) {
        return next(new AppError('User belonging to this token no longer exists.', 401));
    }

    if (user.deletedAt) {
        return next(new AppError('This account has been blocked. Contact support.', 403));
    }

    req.user = user;
    next();
});

/**
 * Authorize by role.
 * Usage: authorize('admin', 'company')
 */
const authorize = (...roles) => {
    return (req, _res, next) => {
        if (!roles.includes(req.user.role)) {
            return next(
                new AppError(`Role '${req.user.role}' is not authorized to access this route.`, 403)
            );
        }
        next();
    };
};

module.exports = { protect, authorize };
