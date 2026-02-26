const express = require('express');
const fs = require('fs');
const path = require('path');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const { uploadAvatar, uploadCV, uploadEventImage } = require('../middleware/upload');
const { uploadFile, getSignedUrl } = require('../utils/storage');
const asyncHandler = require('../utils/asyncHandler');
const AppError = require('../utils/AppError');
const config = require('../config');
const Application = require('../models/Application');
const User = require('../models/User');

router.use(protect);

// ─── Upload Avatar ──────────────────────────────
router.post(
    '/avatar',
    uploadAvatar,
    asyncHandler(async (req, res) => {
        if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });

        const filePath = await uploadFile(req.file.buffer, req.file.originalname, 'avatars', req.file.mimetype);

        // Update user's avatarPath
        await User.findByIdAndUpdate(req.user._id, { avatarPath: filePath });

        res.json({ success: true, data: { filePath } });
    })
);

// ─── Upload CV ──────────────────────────────────
router.post(
    '/cv',
    authorize('normal'),
    uploadCV,
    asyncHandler(async (req, res) => {
        if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });

        const filePath = await uploadFile(req.file.buffer, req.file.originalname, 'cvs', req.file.mimetype);
        res.json({ success: true, data: { filePath } });
    })
);

// ─── Upload Event Image ─────────────────────────
router.post(
    '/event-image',
    authorize('company', 'admin'),
    uploadEventImage,
    asyncHandler(async (req, res) => {
        if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });

        const filePath = await uploadFile(req.file.buffer, req.file.originalname, 'events', req.file.mimetype);
        res.json({ success: true, data: { filePath } });
    })
);

// ─── Get CV (signed / authorized) ───────────────
router.get(
    '/cv/:filename',
    asyncHandler(async (req, res) => {
        const fileKey = `cvs/${req.params.filename}`;

        // Check authorization: only the applicant, event company owner, or admin
        const isAdmin = req.user.role === 'admin';
        if (!isAdmin) {
            // Check if this CV belongs to the requesting user
            const app = await Application.findOne({ cvPath: fileKey, userId: req.user._id });
            if (!app) {
                // Check if requesting user is the company owner of the event
                const anyApp = await Application.findOne({ cvPath: fileKey }).populate({
                    path: 'eventId',
                    populate: { path: 'companyId', select: 'owner' },
                });
                if (
                    !anyApp ||
                    !anyApp.eventId ||
                    !anyApp.eventId.companyId ||
                    anyApp.eventId.companyId.owner.toString() !== req.user._id.toString()
                ) {
                    throw new AppError('Not authorized to access this file', 403);
                }
            }
        }

        if (config.storage.type === 's3') {
            const url = await getSignedUrl(fileKey);
            return res.json({ success: true, data: { url } });
        }

        // Local: stream the file
        const filePath = path.join(config.storage.localDir, fileKey);
        if (!fs.existsSync(filePath)) {
            throw new AppError('File not found', 404);
        }
        res.sendFile(filePath);
    })
);

// ─── Serve local files (protected generic) ──────
router.get(
    '/file/:folder/:filename',
    asyncHandler(async (req, res) => {
        const fileKey = `${req.params.folder}/${req.params.filename}`;

        if (config.storage.type === 's3') {
            const url = await getSignedUrl(fileKey);
            return res.json({ success: true, data: { url } });
        }

        const filePath = path.join(config.storage.localDir, fileKey);
        if (!fs.existsSync(filePath)) {
            throw new AppError('File not found', 404);
        }
        res.sendFile(filePath);
    })
);

module.exports = router;
