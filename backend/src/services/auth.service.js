const User = require('../models/User');
const AppError = require('../utils/AppError');
const { sendEmail } = require('../utils/email');
const {
    generateAccessToken,
    generateRefreshToken,
    verifyRefreshToken,
    generateRandomToken,
    hashToken,
} = require('../utils/tokens');
const config = require('../config');

/**
 * Register a new user.
 */
const register = async ({ email, password, name, nationalIdNumber, role, phone }) => {
    // Check if user exists
    const existing = await User.findOne({ email });
    if (existing) {
        throw new AppError('Email already registered', 400);
    }

    // Check national ID uniqueness
    if (nationalIdNumber) {
        const existingNid = await User.findOne({ nationalIdNumber });
        if (existingNid) {
            throw new AppError('National ID number already registered', 400);
        }
    }

    // Generate email verification token
    const verifyToken = generateRandomToken();

    const user = await User.create({
        email,
        password,
        name,
        nationalIdNumber,
        role: role || 'normal',
        phone,
        emailVerifyToken: hashToken(verifyToken),
        emailVerifyExpires: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24h
    });

    // Generate tokens
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    // Store refresh token
    user.refreshTokens.push({ token: refreshToken });
    await user.save({ validateBeforeSave: false });

    // Send verification email
    try {
        const verifyUrl = `${config.clientUrl}/verify-email/${verifyToken}`;
        await sendEmail({
            to: user.email,
            subject: 'ShiftSphere - Verify Your Email',
            text: `Welcome to ShiftSphere! Please verify your email by visiting: ${verifyUrl}`,
            html: `<h2>Welcome to ShiftSphere!</h2><p>Please verify your email by clicking the link below:</p><a href="${verifyUrl}">Verify Email</a><p>This link expires in 24 hours.</p>`,
        });
    } catch (_err) {
        // Don't block registration if email fails
    }

    return { user, accessToken, refreshToken };
};

/**
 * Login with email and password.
 */
const login = async ({ email, password }) => {
    // Find user with password field
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
        throw new AppError('Invalid email or password', 401);
    }

    if (user.deletedAt) {
        throw new AppError('This account has been blocked. Contact support.', 403);
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
        throw new AppError('Invalid email or password', 401);
    }

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    // Store refresh token
    user.refreshTokens.push({ token: refreshToken });
    await user.save({ validateBeforeSave: false });

    return { user, accessToken, refreshToken };
};

/**
 * Refresh token — rotate tokens.
 */
const refreshTokenService = async (oldRefreshToken) => {
    // Verify the refresh token
    let decoded;
    try {
        decoded = verifyRefreshToken(oldRefreshToken);
    } catch (_err) {
        throw new AppError('Invalid or expired refresh token', 401);
    }

    const user = await User.findById(decoded.id);
    if (!user) {
        throw new AppError('User not found', 401);
    }

    if (user.deletedAt) {
        throw new AppError('This account has been blocked', 403);
    }

    // Check if old refresh token exists in user's tokens
    const tokenIndex = user.refreshTokens.findIndex((t) => t.token === oldRefreshToken);
    if (tokenIndex === -1) {
        // Token reuse detected — invalidate all tokens (security)
        user.refreshTokens = [];
        await user.save({ validateBeforeSave: false });
        throw new AppError('Token reuse detected. All sessions invalidated. Please log in again.', 401);
    }

    // Remove old token
    user.refreshTokens.splice(tokenIndex, 1);

    // Generate new pair
    const accessToken = generateAccessToken(user);
    const newRefreshToken = generateRefreshToken(user);

    user.refreshTokens.push({ token: newRefreshToken });
    await user.save({ validateBeforeSave: false });

    return { accessToken, refreshToken: newRefreshToken };
};

/**
 * Logout current device (remove specific refresh token).
 */
const logout = async (userId, refreshToken) => {
    const user = await User.findById(userId);
    if (!user) return;

    user.refreshTokens = user.refreshTokens.filter((t) => t.token !== refreshToken);
    await user.save({ validateBeforeSave: false });
};

/**
 * Logout all devices (clear all refresh tokens).
 */
const logoutAll = async (userId) => {
    await User.findByIdAndUpdate(userId, { refreshTokens: [] });
};

/**
 * Forgot password — send reset email.
 */
const forgotPassword = async (email) => {
    const user = await User.findOne({ email });
    if (!user) {
        throw new AppError('No user found with that email', 404);
    }

    const resetToken = generateRandomToken();
    user.passwordResetToken = hashToken(resetToken);
    user.passwordResetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour
    await user.save({ validateBeforeSave: false });

    const resetUrl = `${config.clientUrl}/reset-password/${resetToken}`;
    await sendEmail({
        to: user.email,
        subject: 'ShiftSphere - Reset Your Password',
        text: `Reset your password by visiting: ${resetUrl} (expires in 1 hour)`,
        html: `<h2>Password Reset</h2><p>Click below to reset your password:</p><a href="${resetUrl}">Reset Password</a><p>This link expires in 1 hour.</p>`,
    });
};

/**
 * Reset password using token.
 */
const resetPassword = async (token, newPassword) => {
    const hashedToken = hashToken(token);

    const user = await User.findOne({
        passwordResetToken: hashedToken,
        passwordResetExpires: { $gt: Date.now() },
    });

    if (!user) {
        throw new AppError('Invalid or expired reset token', 400);
    }

    user.password = newPassword;
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;
    user.refreshTokens = []; // Force re-login on all devices
    await user.save();
};

/**
 * Verify email using token.
 */
const verifyEmail = async (token) => {
    const hashedToken = hashToken(token);

    const user = await User.findOne({
        emailVerifyToken: hashedToken,
        emailVerifyExpires: { $gt: Date.now() },
    });

    if (!user) {
        throw new AppError('Invalid or expired verification token', 400);
    }

    user.emailVerified = true;
    user.emailVerifyToken = undefined;
    user.emailVerifyExpires = undefined;
    await user.save({ validateBeforeSave: false });

    return user;
};

module.exports = {
    register,
    login,
    refreshToken: refreshTokenService,
    logout,
    logoutAll,
    forgotPassword,
    resetPassword,
    verifyEmail,
};
