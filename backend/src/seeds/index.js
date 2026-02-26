const seedCategories = require('./categories.seed');
const seedAdmin = require('./admin.seed');
const mongoose = require('mongoose');
const config = require('../config');
const logger = require('../utils/logger');

const runAllSeeds = async () => {
    try {
        await mongoose.connect(config.mongoose.uri);
        logger.info('Connected to MongoDB for seeding');

        // Seed categories
        const Category = require('../models/Category');
        const defaultCategories = [
            { name: 'Hospitality', icon: 'hotel' },
            { name: 'Security', icon: 'shield' },
            { name: 'Catering', icon: 'restaurant' },
            { name: 'Cleaning', icon: 'cleaning_services' },
            { name: 'Events & Entertainment', icon: 'celebration' },
            { name: 'Warehousing', icon: 'warehouse' },
            { name: 'Retail', icon: 'store' },
            { name: 'Customer Service', icon: 'support_agent' },
            { name: 'Healthcare', icon: 'local_hospital' },
            { name: 'Transportation', icon: 'local_shipping' },
            { name: 'Construction', icon: 'construction' },
            { name: 'IT & Technology', icon: 'computer' },
            { name: 'Education', icon: 'school' },
            { name: 'Agriculture', icon: 'agriculture' },
            { name: 'Other', icon: 'category' },
        ];

        for (const cat of defaultCategories) {
            await Category.findOneAndUpdate({ name: cat.name }, cat, { upsert: true });
        }
        logger.info(`✅ ${defaultCategories.length} categories seeded`);

        // Seed admin
        const User = require('../models/User');
        const existing = await User.findOne({ email: config.admin.email });
        if (!existing) {
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
        } else {
            logger.info('Admin user already exists, skipping');
        }

        await mongoose.disconnect();
        logger.info('🌱 All seeds completed');
    } catch (err) {
        logger.error('Seeding failed:', err.message);
        process.exit(1);
    }
};

runAllSeeds();
