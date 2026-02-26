const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analytics.controller');
const { protect, authorize } = require('../middleware/auth');

router.use(protect);
router.use(authorize('admin'));

router.get('/kpis', analyticsController.getKPIs);
router.get('/monthly', analyticsController.getMonthlyStats);
router.get('/roles', analyticsController.getRoleDistribution);
router.get('/top-events', analyticsController.getTopEvents);
router.get('/app-status', analyticsController.getApplicationStatusDistribution);
router.get('/event-status', analyticsController.getEventStatusDistribution);

module.exports = router;
