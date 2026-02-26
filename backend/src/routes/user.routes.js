const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { updateProfile } = require('../validations/user.validation');

// All routes require auth
router.use(protect);

router.get('/', authorize('admin'), userController.getAllUsers);
router.patch('/profile', validate(updateProfile), userController.updateProfile);
router.get('/:id', userController.getUserById);
router.patch('/:id/block', authorize('admin'), userController.blockUser);
router.patch('/:id/unblock', authorize('admin'), userController.unblockUser);
router.patch('/:id/change-role', authorize('admin'), userController.changeRole);

module.exports = router;
