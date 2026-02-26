const mongoose = require('mongoose');
const Category = require('../models/Category');
const config = require('../config');
const logger = require('../utils/logger');

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

const seedCategories = async () => {
    try {
        await mongoose.connect(config.mongoose.uri);
        logger.info('Connected to MongoDB');

        for (const cat of defaultCategories) {
            await Category.findOneAndUpdate(
                { name: cat.name },
                cat,
                { upsert: true, new: true }
            );
        }

        logger.info(`✅ ${defaultCategories.length} categories seeded`);
        await mongoose.disconnect();
    } catch (err) {
        logger.error('Seed categories failed:', err.message);
        process.exit(1);
    }
};

// Run directly
if (require.main === module) {
    seedCategories();
}

module.exports = seedCategories;
