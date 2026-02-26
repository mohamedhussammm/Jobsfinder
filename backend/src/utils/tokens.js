const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const config = require('../config');

/**
 * Generate an access token for a user.
 */
const generateAccessToken = (user) => {
    return jwt.sign(
        { id: user._id || user.id, role: user.role },
        config.jwt.accessSecret,
        { expiresIn: config.jwt.accessExpiresIn }
    );
};

/**
 * Generate a refresh token for a user.
 */
const generateRefreshToken = (user) => {
    return jwt.sign(
        { id: user._id || user.id, role: user.role },
        config.jwt.refreshSecret,
        { expiresIn: config.jwt.refreshExpiresIn }
    );
};

/**
 * Verify an access token.
 */
const verifyAccessToken = (token) => {
    return jwt.verify(token, config.jwt.accessSecret);
};

/**
 * Verify a refresh token.
 */
const verifyRefreshToken = (token) => {
    return jwt.verify(token, config.jwt.refreshSecret);
};

/**
 * Generate a random hex token for email verification / password reset.
 */
const generateRandomToken = () => {
    return crypto.randomBytes(32).toString('hex');
};

/**
 * Hash a token for secure storage.
 */
const hashToken = (token) => {
    return crypto.createHash('sha256').update(token).digest('hex');
};

module.exports = {
    generateAccessToken,
    generateRefreshToken,
    verifyAccessToken,
    verifyRefreshToken,
    generateRandomToken,
    hashToken,
};
