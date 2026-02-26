const asyncHandler = require('../utils/asyncHandler');
const authService = require('../services/auth.service');
const googleAuthService = require('../services/google-auth.service');

exports.googleSignIn = asyncHandler(async (req, res) => {
    const { token, tokenType } = req.body;
    console.log('[GoogleSignIn] Received request:', { tokenType, tokenLength: token?.length });
    if (!token) {
        return res.status(400).json({ success: false, message: 'token is required' });
    }
    try {
        const { user, accessToken, refreshToken } = await googleAuthService.googleSignIn(token, tokenType || 'idToken');
        console.log('[GoogleSignIn] Success for user:', user.email);
        res.status(200).json({
            success: true,
            message: 'Google sign-in successful',
            data: { user, accessToken, refreshToken },
        });
    } catch (err) {
        console.error('[GoogleSignIn] Error:', err.message, err.stack);
        throw err;
    }
});

exports.register = asyncHandler(async (req, res) => {
    const { user, accessToken, refreshToken } = await authService.register(req.body);
    res.status(201).json({
        success: true,
        message: 'Registration successful. Please verify your email.',
        data: { user, accessToken, refreshToken },
    });
});

exports.login = asyncHandler(async (req, res) => {
    const { user, accessToken, refreshToken } = await authService.login(req.body);
    res.status(200).json({
        success: true,
        message: 'Login successful',
        data: { user, accessToken, refreshToken },
    });
});

exports.refreshToken = asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    const tokens = await authService.refreshToken(refreshToken);
    res.status(200).json({
        success: true,
        data: tokens,
    });
});

exports.logout = asyncHandler(async (req, res) => {
    await authService.logout(req.user._id, req.body.refreshToken);
    res.status(200).json({ success: true, message: 'Logged out successfully' });
});

exports.logoutAll = asyncHandler(async (req, res) => {
    await authService.logoutAll(req.user._id);
    res.status(200).json({ success: true, message: 'Logged out from all devices' });
});

exports.forgotPassword = asyncHandler(async (req, res) => {
    await authService.forgotPassword(req.body.email);
    res.status(200).json({
        success: true,
        message: 'Password reset email sent. Check your inbox.',
    });
});

exports.resetPassword = asyncHandler(async (req, res) => {
    await authService.resetPassword(req.params.token, req.body.password);
    res.status(200).json({
        success: true,
        message: 'Password reset successful. Please log in.',
    });
});

exports.verifyEmail = asyncHandler(async (req, res) => {
    await authService.verifyEmail(req.params.token);
    res.status(200).json({
        success: true,
        message: 'Email verified successfully',
    });
});

exports.getMe = asyncHandler(async (req, res) => {
    res.status(200).json({
        success: true,
        data: { user: req.user },
    });
});
