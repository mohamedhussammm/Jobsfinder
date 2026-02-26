const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/category.controller');
const { protect, authorize } = require('../middleware/auth');

router.get('/', categoryController.getAllCategories);

// Admin only
router.post('/', protect, authorize('admin'), categoryController.createCategory);
router.patch('/:id', protect, authorize('admin'), categoryController.updateCategory);
router.delete('/:id', protect, authorize('admin'), categoryController.deleteCategory);

module.exports = router;
