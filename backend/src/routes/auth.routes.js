const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const validate = require('../middleware/validate');
const { protect } = require('../middleware/auth');
const authValidation = require('../validations/auth.validation');

router.post('/register', validate(authValidation.register), authController.register);
router.post('/google', authController.googleSignIn);
router.post('/login', validate(authValidation.login), authController.login);
router.post('/refresh-token', validate(authValidation.refreshToken), authController.refreshToken);
router.post('/logout', protect, authController.logout);
router.post('/logout-all', protect, authController.logoutAll);
router.post('/forgot-password', validate(authValidation.forgotPassword), authController.forgotPassword);
router.post('/reset-password/:token', validate(authValidation.resetPassword), authController.resetPassword);
router.get('/verify-email/:token', authController.verifyEmail);
router.get('/me', protect, authController.getMe);

module.exports = router;
