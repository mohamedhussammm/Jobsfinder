const mongoose = require('mongoose');
const User = require('../models/User');
const Company = require('../models/Company');
const Category = require('../models/Category');
const Event = require('../models/Event');
const config = require('../config');
const logger = require('../utils/logger');

const seedProduction = async () => {
    try {
        await mongoose.connect(config.mongoose.uri);
        logger.info('Connected to MongoDB for PRODUCTION seeding');

        // 1. Create Admin
        const adminEmail = 'admin@shiftsphere.com';
        const adminPassword = 'Admin@123';
        await User.findOneAndDelete({ email: adminEmail });
        await User.create({
            email: adminEmail,
            password: adminPassword,
            name: 'System Admin',
            role: 'admin',
            nationalIdNumber: 'ADMIN-PROD-001',
            emailVerified: true,
            profileComplete: true,
        });
        logger.info('✅ Admin created: admin@shiftsphere.com');

        // 2. Create Categories
        const categories = [
            { name: 'Technology', icon: 'computer' },
            { name: 'Marketing', icon: 'campaign' },
            { name: 'Finance', icon: 'payments' },
            { name: 'Hospitality', icon: 'restaurant' },
            { name: 'Logistics', icon: 'local_shipping' },
            { name: 'Security', icon: 'security' },
            { name: 'Retail', icon: 'shopping_bag' },
            { name: 'Healthcare', icon: 'medical_services' },
            { name: 'Education', icon: 'school' },
            { name: 'Entertainment', icon: 'movie' }
        ];
        const catDocs = [];
        for (const cat of categories) {
            const doc = await Category.findOneAndUpdate(
                { name: cat.name },
                { name: cat.name, icon: cat.icon },
                { upsert: true, new: true }
            );
            catDocs.push(doc);
        }
        logger.info('✅ 10 Categories ready');

        // 3. Create 10 Companies (and owners)
        const companiesData = [
            { name: 'TechFlow Solutions', email: 'owner1@techflow.com' },
            { name: 'Starlight Marketing', email: 'owner2@starlight.com' },
            { name: 'Peak Financial', email: 'owner3@peak.com' },
            { name: 'Grand Horizon Hotels', email: 'owner4@grandhorizon.com' },
            { name: 'Swift Logistics Hub', email: 'owner5@swiftlog.com' },
            { name: 'IronClad Security', email: 'owner6@ironclad.com' },
            { name: 'Urban Retail Group', email: 'owner7@urbanretail.com' },
            { name: 'Global Care Health', email: 'owner8@globalcare.com' },
            { name: 'Nexus Education', email: 'owner9@nexus.com' },
            { name: 'Vibrant Events Co', email: 'owner10@vibrant.com' }
        ];

        const companyDocs = [];
        for (let i = 0; i < companiesData.size || i < 10; i++) {
            const data = companiesData[i];
            await User.findOneAndDelete({ email: data.email });
            const owner = await User.create({
                email: data.email,
                password: 'Password@123',
                name: `${data.name} Manager`,
                role: 'company',
                nationalIdNumber: `NID-OWNER-00${i + 1}`,
                emailVerified: true,
                profileComplete: true,
            });

            const company = await Company.findOneAndUpdate(
                { owner: owner._id },
                {
                    name: data.name,
                    description: `Premium services by ${data.name}. Leading the industry with excellence.`,
                    verified: true,
                    logoPath: `https://images.unsplash.com/photo-${1560179707 + i}-97bfa70d56c7?w=200&h=200&fit=crop`
                },
                { upsert: true, new: true }
            );
            companyDocs.push(company);
        }
        logger.info('✅ 10 Companies and Owners ready');

        // 4. Create 10 Team Leaders
        for (let i = 1; i <= 10; i++) {
            const email = `leader${i}@shiftsphere.com`;
            await User.findOneAndDelete({ email });
            await User.create({
                email,
                password: 'Password@123',
                name: `Team Leader ${i}`,
                role: 'team_leader',
                nationalIdNumber: `NID-TL-PROD-00${i}`,
                emailVerified: true,
                profileComplete: true,
            });
        }
        logger.info('✅ 10 Team Leaders ready');

        // 5. Create 10 Events
        const eventsData = [
            { title: 'Global Tech Expo 2026', imageId: '1504386106331-c0a0629a9a35' },
            { title: 'Summer Yacht Party Staffing', imageId: '1544924405-b0dcc4977464' },
            { title: 'Modern Finance Seminar', imageId: '1454165833019-d8b7c0b1c831' },
            { title: 'Luxury Hotel Gala Dinner', imageId: '1519167758481-83f550bb49b3' },
            { title: 'Logistics Center Peak Shift', imageId: '1586528116311-ad8dd3c8310d' },
            { title: 'Cyber Security Conference', imageId: '1550751827-4bd374c3f58b' },
            { title: 'Fashion Week Retail Support', imageId: '1441986300917-64674bd600d8' },
            { title: 'Healthcare Volunteer Drive', imageId: '1505751172107-573228a64220' },
            { title: 'Grand University Graduation', imageId: '1523050335232-942f4fd46a6f' },
            { title: 'Music Festival Weekend', imageId: '1459749411175-04bf5292ceea' }
        ];

        for (let i = 0; i < 10; i++) {
            const ev = eventsData[i];
            const company = companyDocs[i];
            const category = catDocs[i % catDocs.length];

            await Event.create({
                companyId: company._id,
                title: ev.title,
                description: `Join us for the ${ev.title}. We are looking for professional staff to ensure a seamless experience. Competitive pay and great environment.`,
                location: {
                    address: i % 2 === 0 ? 'Cairo, Egypt' : 'Alexandria, Egypt',
                    lat: 30.0444,
                    lng: 31.2357
                },
                startTime: new Date(Date.now() + (i + 5) * 24 * 60 * 60 * 1000),
                endTime: new Date(Date.now() + (i + 5) * 24 * 60 * 60 * 1000 + 8 * 60 * 60 * 1000),
                capacity: 50 + (i * 10),
                imagePath: `https://images.unsplash.com/photo-${ev.imageId}?w=1200&q=80`,
                categoryId: category._id,
                status: 'published',
                salary: 400 + (i * 50),
                requirements: '• Professional appearance\n• Punctuality\n• Good communication skills',
                benefits: '• Competitive daily pay\n• Meals provided\n• Transportation allowance',
                contactEmail: company.owner.email,
                contactPhone: '+20123456789' + i,
                isUrgent: i % 3 === 0
            });
        }
        logger.info('✅ 10 Events ready');

        logger.info('🚀 PRODUCTION SEEDING COMPLETED!');
        await mongoose.disconnect();
        process.exit(0);
    } catch (err) {
        logger.error('❌ Seeding failed:', err.message);
        process.exit(1);
    }
};

seedProduction();
