const multer = require('multer');
const AppError = require('../utils/AppError');

// Store files in memory buffer — we upload them via storage utility
const storage = multer.memoryStorage();

const fileFilter = (allowedTypes) => (_req, file, cb) => {
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new AppError(`File type not allowed. Allowed: ${allowedTypes.join(', ')}`, 400), false);
    }
};

/**
 * Avatar upload — images only, max 5MB
 */
const uploadAvatar = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: fileFilter(['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
}).single('avatar');

/**
 * CV upload — PDFs and docs, max 10MB
 */
const uploadCV = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: fileFilter([
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ]),
}).single('cv');

/**
 * Event image upload — images only, max 10MB
 */
const uploadEventImage = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: fileFilter(['image/jpeg', 'image/png', 'image/webp']),
}).single('image');

/**
 * Company logo upload — images only, max 5MB
 */
const uploadLogo = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: fileFilter(['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml']),
}).single('logo');

module.exports = { uploadAvatar, uploadCV, uploadEventImage, uploadLogo };
