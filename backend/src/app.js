const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const cookieParser = require('cookie-parser');
const mongoSanitize = require('express-mongo-sanitize');
const rateLimit = require('express-rate-limit');
const path = require('path');
const config = require('./config');
const errorHandler = require('./middleware/errorHandler');
const AppError = require('./utils/AppError');

// Import routes
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const companyRoutes = require('./routes/company.routes');
const categoryRoutes = require('./routes/category.routes');
const eventRoutes = require('./routes/event.routes');
const applicationRoutes = require('./routes/application.routes');
const teamLeaderRoutes = require('./routes/teamLeader.routes');
const ratingRoutes = require('./routes/rating.routes');
const notificationRoutes = require('./routes/notification.routes');
const auditLogRoutes = require('./routes/auditLog.routes');
const analyticsRoutes = require('./routes/analytics.routes');
const uploadRoutes = require('./routes/upload.routes');

const app = express();

// ─── Security Headers ───────────────────────────
app.use(helmet());

// ─── CORS ───────────────────────────────────────
app.use(
    cors({
        origin: config.env === 'development' ? true : config.clientUrl,
        credentials: true,
    })
);

// ─── Rate Limiting ──────────────────────────────
const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100000,
    message: { success: false, message: 'Too many requests, please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
});

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100000,
    message: { success: false, message: 'Too many auth attempts, please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
});

app.use('/api', generalLimiter);
app.use('/api/auth', authLimiter);

// ─── Body Parsers ───────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cookieParser());

// ─── Data Sanitization ─────────────────────────
app.use(mongoSanitize()); // NoSQL injection prevention

// ─── Logging ────────────────────────────────────
if (config.env === 'development') {
    app.use(morgan('dev'));
} else {
    app.use(morgan('combined'));
}

// ─── Static Files (Local Uploads) ──────────────
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ─── API Routes ─────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/companies', companyRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/applications', applicationRoutes);
app.use('/api/team-leaders', teamLeaderRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/audit-logs', auditLogRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/upload', uploadRoutes);

// ─── Health Check ───────────────────────────────
app.get('/api/health', (_req, res) => {
    res.json({ success: true, message: 'ShiftSphere API is running', timestamp: new Date() });
});

// ─── 404 Handler ────────────────────────────────
app.all('*', (req, _res, next) => {
    next(new AppError(`Route ${req.originalUrl} not found`, 404));
});

// ─── Global Error Handler ───────────────────────
app.use(errorHandler);

module.exports = app;
