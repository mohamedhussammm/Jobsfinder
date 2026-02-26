/**
 * Seed script — creates 1 company, 3 categories, and 5 published events.
 * Usage: node src/seed-events.js
 */
const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const User = require('./models/User');
const Company = require('./models/Company');
const Category = require('./models/Category');
const Event = require('./models/Event');

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/shiftsphere';

const categories = [
    { name: 'Hospitality', icon: '🏨' },
    { name: 'Security', icon: '🔒' },
    { name: 'Logistics', icon: '📦' },
];

const events = [
    {
        title: 'Grand Hotel Gala Night',
        description: 'Premium hospitality event at the Grand Hotel. Looking for experienced waiters, bartenders, and event coordinators for a black-tie gala dinner serving 500 guests.',
        location: { address: 'Grand Hotel, Downtown Cairo', lat: 30.0444, lng: 31.2357 },
        startTime: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),  // 1 week from now
        endTime: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000 + 8 * 60 * 60 * 1000),
        capacity: 50,
        imagePath: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=800',
        categoryIndex: 0,
    },
    {
        title: 'Tech Conference Security Team',
        description: 'Large-scale tech conference needs a professional security team. Duties include access control, crowd management, and VIP protection for 3-day event.',
        location: { address: 'Egypt International Exhibition Center, Nasr City', lat: 30.0626, lng: 31.3398 },
        startTime: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        endTime: new Date(Date.now() + 16 * 24 * 60 * 60 * 1000),
        capacity: 30,
        imagePath: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
        categoryIndex: 1,
    },
    {
        title: 'Warehouse Logistics Sprint',
        description: 'Fast-paced warehouse operation needs additional hands for seasonal inventory management. Forklift operators, packers, and inventory clerks welcome.',
        location: { address: '10th of Ramadan Industrial Zone', lat: 30.2965, lng: 31.7650 },
        startTime: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
        endTime: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
        capacity: 100,
        imagePath: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800',
        categoryIndex: 2,
    },
    {
        title: 'Beach Resort Summer Staff',
        description: 'Luxury beach resort hiring summer staff for the peak season! Positions include lifeguards, pool attendants, restaurant servers, and recreation coordinators.',
        location: { address: 'Ain Sokhna Resort, Red Sea', lat: 29.6006, lng: 32.3129 },
        startTime: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
        endTime: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
        capacity: 75,
        imagePath: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
        categoryIndex: 0,
    },
    {
        title: 'Music Festival Crew',
        description: 'Annual music festival looking for stage crew, sound technicians, lighting operators, and backstage coordinators. Experience in live events preferred.',
        location: { address: 'Al-Azhar Park, Cairo', lat: 30.0392, lng: 31.2636 },
        startTime: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
        endTime: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000),
        capacity: 40,
        imagePath: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
        categoryIndex: 1,
    },
];

async function seed() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('Connected to MongoDB');

        // 1. Find or create a company owner user
        let owner = await User.findOne({ role: 'company' });
        if (!owner) {
            owner = await User.findOne(); // fallback: any user
        }
        if (!owner) {
            console.error('No users in DB. Please sign in first, then run this script.');
            process.exit(1);
        }
        console.log(`Using owner: ${owner.email} (${owner._id})`);

        // 2. Find or create company
        let company = await Company.findOne({ owner: owner._id });
        if (!company) {
            company = await Company.create({
                owner: owner._id,
                name: 'ShiftSphere Events Co.',
                description: 'Premier event staffing company',
                verified: true,
            });
            console.log(`Created company: ${company.name}`);
        } else {
            console.log(`Using existing company: ${company.name}`);
        }

        // 3. Upsert categories
        const catDocs = [];
        for (const cat of categories) {
            const doc = await Category.findOneAndUpdate(
                { name: cat.name },
                cat,
                { upsert: true, new: true }
            );
            catDocs.push(doc);
        }
        console.log(`Categories ready: ${catDocs.map(c => c.name).join(', ')}`);

        // 4. Create events (skip if 5+ published events already exist)
        const existingCount = await Event.countDocuments({ status: 'published' });
        if (existingCount >= 5) {
            console.log(`Already have ${existingCount} published events. Skipping.`);
        } else {
            for (const ev of events) {
                const category = catDocs[ev.categoryIndex];
                await Event.create({
                    companyId: company._id,
                    title: ev.title,
                    description: ev.description,
                    location: ev.location,
                    startTime: ev.startTime,
                    endTime: ev.endTime,
                    capacity: ev.capacity,
                    imagePath: ev.imagePath,
                    categoryId: category._id,
                    status: 'published',
                });
                console.log(`  ✓ Created event: ${ev.title}`);
            }
            console.log('All 5 events seeded!');
        }

        await mongoose.disconnect();
        console.log('Done!');
        process.exit(0);
    } catch (err) {
        console.error('Seed error:', err);
        process.exit(1);
    }
}

seed();
