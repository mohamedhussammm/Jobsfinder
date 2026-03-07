const mongoose = require('mongoose');
const User = require('../models/User');
const Company = require('../models/Company');
const Category = require('../models/Category');
const Event = require('../models/Event');
const config = require('../config');
const logger = require('../utils/logger');

const seedDataset = async () => {
    try {
        await mongoose.connect(config.mongoose.uri);
        logger.info('Connected to MongoDB for bulk seeding');

        // 1. Create 10 Users with various roles
        const usersData = [
            { email: 'admin2@shiftsphere.com', password: 'Password@123', name: 'Admin Two', role: 'admin', nationalIdNumber: 'NID-ADM-002' },
            { email: 'company1@shiftsphere.com', password: 'Password@123', name: 'Tech Events Corp', role: 'company', nationalIdNumber: 'NID-COM-001' },
            { email: 'company2@shiftsphere.com', password: 'Password@123', name: 'Global Staffing', role: 'company', nationalIdNumber: 'NID-COM-002' },
            { email: 'leader1@shiftsphere.com', password: 'Password@123', name: 'John Captain', role: 'team_leader', nationalIdNumber: 'NID-TL-001' },
            { email: 'leader2@shiftsphere.com', password: 'Password@123', name: 'Sarah Chief', role: 'team_leader', nationalIdNumber: 'NID-TL-002' },
            { email: 'leader3@shiftsphere.com', password: 'Password@123', name: 'Mike Lead', role: 'team_leader', nationalIdNumber: 'NID-TL-003' },
            { email: 'user1@shiftsphere.com', password: 'Password@123', name: 'Alice Worker', role: 'normal', nationalIdNumber: 'NID-USR-001' },
            { email: 'user2@shiftsphere.com', password: 'Password@123', name: 'Bob Usher', role: 'normal', nationalIdNumber: 'NID-USR-002' },
            { email: 'user3@shiftsphere.com', password: 'Password@123', name: 'Charlie Helper', role: 'normal', nationalIdNumber: 'NID-USR-003' },
            { email: 'user4@shiftsphere.com', password: 'Password@123', name: 'Diana Staff', role: 'normal', nationalIdNumber: 'NID-USR-004' },
        ];

        const createdUsers = [];
        for (const u of usersData) {
            const existing = await User.findOne({ email: u.email });
            if (!existing) {
                const user = await User.create({ ...u, emailVerified: true, profileComplete: true });
                createdUsers.push(user);
                logger.info(`  ✓ Created user: ${u.email}`);
            } else {
                createdUsers.push(existing);
            }
        }

        // 2. Create Companies for the company users
        const company1 = await Company.findOneAndUpdate(
            { owner: createdUsers[1]._id },
            { name: 'Tech Events Corp', description: 'Specializing in tech conferences', verified: true },
            { upsert: true, new: true }
        );
        const company2 = await Company.findOneAndUpdate(
            { owner: createdUsers[2]._id },
            { name: 'Global Staffing', description: 'General event staffing solutions', verified: true },
            { upsert: true, new: true }
        );
        logger.info('✅ Companies ready');

        // 3. Ensure Categories exist
        const categories = ['Hospitality', 'Security', 'Logistics', 'IT', 'Retail'];
        const catDocs = [];
        for (const name of categories) {
            const cat = await Category.findOneAndUpdate({ name }, { name, icon: 'category' }, { upsert: true, new: true });
            catDocs.push(cat);
        }
        logger.info('✅ Categories ready');

        // 4. Create 10 Events
        const eventsData = [
            { title: 'AI Summit 2026', description: 'The biggest AI conference in the region.', location: { address: 'Cairo Convention Center' }, category: 'IT', company: company1, image: 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800' },
            { title: 'Summer Music Festival', description: '3 days of non-stop music.', location: { address: 'North Coast Arena' }, category: 'Hospitality', company: company2, image: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800' },
            { title: 'Global Trade Expo', description: 'B2B networking and exhibition.', location: { address: 'International Fair Grounds' }, category: 'Logistics', company: company1, image: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800' },
            { title: 'Security Summit', description: 'National security and tech expo.', location: { address: 'Defense Center' }, category: 'Security', company: company1, image: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800' },
            { title: 'Marathon 2026 Volunteers', description: 'Help manage the annual marathon.', location: { address: 'Zamalek District' }, category: 'Hospitality', company: company2, image: 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=800' },
            { title: 'New Year Warehouse Rush', description: 'Seasonal staffing for logistics hub.', location: { address: 'Industrial City 1' }, category: 'Logistics', company: company2, image: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800' },
            { title: 'Gaming Championship', description: 'Esports tournament staffing.', location: { address: 'Cyber Arena' }, category: 'IT', company: company1, image: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800' },
            { title: 'Black Friday Retail Support', description: 'Helping malls manage the rush.', location: { address: 'Mall of Egypt' }, category: 'Retail', company: company2, image: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800' },
            { title: 'Fine Dining Gala', description: 'High-end catering event.', location: { address: 'Nile Ritz Carlton' }, category: 'Hospitality', company: company1, image: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=800' },
            { title: 'Airport Logistics Support', description: 'Managing baggage flow during peak.', location: { address: 'Cairo Airport T3' }, category: 'Logistics', company: company2, image: 'https://images.unsplash.com/photo-1530521954074-e64f6810b32d?w=800' },
        ];

        for (const ev of eventsData) {
            const category = catDocs.find(c => c.name === ev.category);
            await Event.create({
                companyId: ev.company._id,
                title: ev.title,
                description: ev.description,
                location: ev.location,
                startTime: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 1 month from now
                endTime: new Date(Date.now() + 31 * 24 * 60 * 60 * 1000),
                capacity: 100,
                imagePath: ev.image,
                categoryId: category._id,
                status: 'published',
                salary: 500,
                contactEmail: ev.company.owner.email,
                contactPhone: '0123456789',
            });
            logger.info(`  ✓ Created event: ${ev.title}`);
        }

        logger.info('🌱 Bulk seeding completed successfully!');
        await mongoose.disconnect();
        process.exit(0);
    } catch (err) {
        logger.error('Bulk seeding failed:', err.message);
        process.exit(1);
    }
};

seedDataset();
