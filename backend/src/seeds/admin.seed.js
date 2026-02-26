const mongoose = require('mongoose');
const User = require('../models/User');
const config = require('../config');
const logger = require('../utils/logger');

const seedAdmin = async () => {
    try {
        await mongoose.connect(config.mongoose.uri);
        logger.info('Connected to MongoDB');

        const existing = await User.findOne({ email: config.admin.email });
        if (existing) {
            logger.info('Admin user already exists, skipping');
            await mongoose.disconnect();
            return;
        }

        await User.create({
            email: config.admin.email,
            password: config.admin.password,
            name: config.admin.name,
            role: 'admin',
            nationalIdNumber: 'ADMIN-001',
            emailVerified: true,
            profileComplete: true,
        });

        logger.info(`✅ Admin user created: ${config.admin.email}`);
        await mongoose.disconnect();
    } catch (err) {
        logger.error('Seed admin failed:', err.message);
        process.exit(1);
    }
};

// Run directly
if (require.main === module) {
    seedAdmin();
}

module.exports = seedAdmin;
