const { Server } = require('socket.io');
const { verifyAccessToken } = require('../utils/tokens');
const User = require('../models/User');
const logger = require('../utils/logger');
const config = require('../config');

let io;

const initSocket = (httpServer) => {
    io = new Server(httpServer, {
        cors: {
            origin: config.clientUrl,
            methods: ['GET', 'POST'],
            credentials: true,
        },
    });

    // ─── Authentication Middleware ───────────────
    io.use(async (socket, next) => {
        try {
            const token = socket.handshake.auth?.token || socket.handshake.query?.token;
            if (!token) {
                return next(new Error('Authentication required'));
            }

            const decoded = verifyAccessToken(token);
            const user = await User.findById(decoded.id).select('name role email');
            if (!user) {
                return next(new Error('User not found'));
            }

            socket.user = user;
            next();
        } catch (err) {
            next(new Error('Invalid token'));
        }
    });

    // ─── Connection Handler ─────────────────────
    io.on('connection', (socket) => {
        const userId = socket.user._id.toString();
        logger.info(`🔌 Socket connected: ${socket.user.name} (${userId})`);

        // Join user's personal room for notifications
        socket.join(`user:${userId}`);

        // Join role-based rooms
        socket.join(`role:${socket.user.role}`);

        // ─── Chat ──────────────────────────────
        socket.on('chat:join', (roomId) => {
            socket.join(`chat:${roomId}`);
            logger.debug(`${socket.user.name} joined chat room: ${roomId}`);
        });

        socket.on('chat:leave', (roomId) => {
            socket.leave(`chat:${roomId}`);
        });

        socket.on('chat:message', (data) => {
            const { roomId, message } = data;
            io.to(`chat:${roomId}`).emit('chat:message', {
                senderId: userId,
                senderName: socket.user.name,
                message,
                timestamp: new Date(),
            });
        });

        socket.on('chat:typing', (data) => {
            const { roomId } = data;
            socket.to(`chat:${roomId}`).emit('chat:typing', {
                userId,
                name: socket.user.name,
            });
        });

        // ─── Disconnect ────────────────────────
        socket.on('disconnect', () => {
            logger.info(`🔌 Socket disconnected: ${socket.user.name}`);
        });
    });

    logger.info('⚡ Socket.io initialized');
    return io;
};

/**
 * Send a realtime notification to a specific user.
 */
const notifyUser = (userId, event, data) => {
    if (io) {
        io.to(`user:${userId}`).emit(event, data);
    }
};

/**
 * Send a notification to all users with a specific role.
 */
const notifyRole = (role, event, data) => {
    if (io) {
        io.to(`role:${role}`).emit(event, data);
    }
};

/**
 * Get the Socket.io instance.
 */
const getIO = () => io;

module.exports = { initSocket, notifyUser, notifyRole, getIO };
