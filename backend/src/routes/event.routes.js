const express = require('express');
const router = express.Router();
const eventController = require('../controllers/event.controller');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { createEvent, updateEvent, rejectEvent } = require('../validations/event.validation');
const { uploadEventImage } = require('../middleware/upload');
const { uploadFile } = require('../utils/storage');
const asyncHandler = require('../utils/asyncHandler');

// Public
router.get('/', eventController.getPublishedEvents);
router.get('/search', eventController.searchEvents);
router.get('/:id', eventController.getEventById);

// Protected
router.use(protect);

router.post('/', authorize('company', 'admin'), validate(createEvent), eventController.createEvent);
router.get('/status/pending', authorize('admin'), eventController.getPendingEvents);
router.get('/company/:companyId', authorize('company', 'admin'), eventController.getCompanyEvents);

router.patch('/:id', authorize('company', 'admin'), validate(updateEvent), eventController.updateEvent);
router.patch('/:id/approve', authorize('admin'), eventController.approveEvent);
router.patch('/:id/reject', authorize('admin'), validate(rejectEvent), eventController.rejectEvent);

// Upload event image
router.post(
    '/:id/image',
    authorize('company', 'admin'),
    uploadEventImage,
    asyncHandler(async (req, res) => {
        if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });
        const filePath = await uploadFile(req.file.buffer, req.file.originalname, 'events', req.file.mimetype);
        const Event = require('../models/Event');
        const event = await Event.findByIdAndUpdate(req.params.id, { imagePath: filePath }, { new: true });
        res.json({ success: true, data: { event, imagePath: filePath } });
    })
);

router.delete('/:id', authorize('admin'), eventController.deleteEvent);

module.exports = router;
