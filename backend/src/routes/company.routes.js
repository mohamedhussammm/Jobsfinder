const express = require('express');
const router = express.Router();
const companyController = require('../controllers/company.controller');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { createCompany, updateCompany } = require('../validations/company.validation');
const { uploadLogo } = require('../middleware/upload');
const { uploadFile } = require('../utils/storage');
const asyncHandler = require('../utils/asyncHandler');

router.get('/', companyController.getAllCompanies);
router.get('/mine', protect, authorize('company'), companyController.getMyCompany);
router.get('/:id', companyController.getCompanyById);

router.post(
    '/',
    protect,
    authorize('company'),
    validate(createCompany),
    companyController.createCompany
);

router.patch(
    '/:id',
    protect,
    authorize('company', 'admin'),
    validate(updateCompany),
    companyController.updateCompany
);

// Upload company logo
router.post(
    '/:id/logo',
    protect,
    authorize('company', 'admin'),
    uploadLogo,
    asyncHandler(async (req, res) => {
        if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });
        const filePath = await uploadFile(req.file.buffer, req.file.originalname, 'logos', req.file.mimetype);
        const Company = require('../models/Company');
        const company = await Company.findByIdAndUpdate(req.params.id, { logoPath: filePath }, { new: true });
        res.json({ success: true, data: { company, logoPath: filePath } });
    })
);

router.patch('/:id/verify', protect, authorize('admin'), companyController.verifyCompany);

module.exports = router;
