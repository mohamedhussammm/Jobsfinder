const http = require('http');
const mongoose = require('mongoose');
const app = require('./app');
const config = require('./config');
const logger = require('./utils/logger');
const { initSocket } = require('./sockets');

// ─── Handle uncaught exceptions ─────────────────
process.on('uncaughtException', (err) => {
    logger.error('UNCAUGHT EXCEPTION! Shutting down...');
    logger.error(err.name, err.message, err.stack);
    process.exit(1);
});

// ─── Create HTTP Server ─────────────────────────
const server = http.createServer(app);

// ─── Initialize Socket.io ───────────────────────
initSocket(server);

// ─── Connect to MongoDB & Start Server ──────────
const startServer = async () => {
    try {
        await mongoose.connect(config.mongoose.uri, config.mongoose.options);
        logger.info(`✅ MongoDB connected: ${mongoose.connection.host}`);

        server.listen(config.port, () => {
            logger.info(`🚀 Server running in ${config.env} mode on port ${config.port}`);
            logger.info(`📡 API: http://localhost:${config.port}/api`);
            logger.info(`❤️  Health: http://localhost:${config.port}/api/health`);
        });
    } catch (error) {
        logger.error('❌ Failed to start server:', error.message);
        process.exit(1);
    }
};

startServer();

// ─── Handle unhandled rejections ────────────────
process.on('unhandledRejection', (err) => {
    logger.error('UNHANDLED REJECTION! Shutting down...');
    logger.error(err.name, err.message);
    server.close(() => process.exit(1));
});

// ─── Graceful shutdown on SIGTERM ───────────────
process.on('SIGTERM', () => {
    logger.info('SIGTERM received. Shutting down gracefully...');
    server.close(() => {
        mongoose.connection.close();
        logger.info('Process terminated.');
    });
});
