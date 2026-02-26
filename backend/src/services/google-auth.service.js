const { OAuth2Client } = require('google-auth-library');
const https = require('https');
const User = require('../models/User');
const config = require('../config');
const AppError = require('../utils/AppError');
const { generateAccessToken, generateRefreshToken } = require('../utils/tokens');

const googleClient = new OAuth2Client(config.google.clientId);

/** Simple GET helper using Node built-in https */
const httpsGet = (url, headers) =>
    new Promise((resolve, reject) => {
        https.get(url, { headers }, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(JSON.parse(data));
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        }).on('error', reject);
    });

/**
 * Verify a Google token (idToken or accessToken) and return Google user info.
 */
const verifyGoogleToken = async (token, tokenType) => {
    if (tokenType === 'idToken') {
        // Verify ID token (Android / server-side flow)
        let ticket;
        try {
            ticket = await googleClient.verifyIdToken({
                idToken: token,
                audience: config.google.clientId,
            });
        } catch (_err) {
            throw new AppError('Invalid Google ID token', 401);
        }
        const payload = ticket.getPayload();
        return {
            googleId: payload.sub,
            email: payload.email,
            name: payload.name,
            picture: payload.picture,
        };
    } else if (tokenType === 'accessToken') {
        // Verify access token (Web flow) via Google userinfo endpoint
        try {
            const data = await httpsGet(
                'https://www.googleapis.com/oauth2/v3/userinfo',
                { Authorization: `Bearer ${token}` }
            );
            return {
                googleId: data.sub,
                email: data.email,
                name: data.name,
                picture: data.picture,
            };
        } catch (_err) {
            throw new AppError('Invalid Google access token', 401);
        }
    } else {
        throw new AppError('Invalid token type', 400);
    }
};

/**
 * Find or create user from Google profile, return JWT tokens.
 */
const googleSignIn = async (token, tokenType = 'idToken') => {
    const { googleId, email, name, picture } = await verifyGoogleToken(token, tokenType);

    if (!email) {
        throw new AppError('Google account has no email', 400);
    }

    // Find existing user by googleId OR email
    let user = await User.findOne({
        $or: [{ googleId }, { email }],
    });

    if (user) {
        // Link Google account if user exists by email but not yet linked
        if (!user.googleId) {
            user.googleId = googleId;
            user.authProvider = 'google';
            if (picture && !user.avatarPath) {
                user.avatarPath = picture;
            }
            await user.save({ validateBeforeSave: false });
        }

        // Check if user is blocked
        if (user.deletedAt) {
            throw new AppError('This account has been blocked. Contact support.', 403);
        }
    } else {
        // Create a new user
        user = await User.create({
            email,
            name: name || email.split('@')[0],
            googleId,
            authProvider: 'google',
            avatarPath: picture || undefined,
            role: 'normal',
            emailVerified: true,
        });
    }

    // Generate JWT tokens
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    user.refreshTokens.push({ token: refreshToken });
    await user.save({ validateBeforeSave: false });

    return { user, accessToken, refreshToken };
};

module.exports = { googleSignIn };
