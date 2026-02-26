const asyncHandler = require('../utils/asyncHandler');
const analyticsService = require('../services/analytics.service');

exports.getKPIs = asyncHandler(async (_req, res) => {
    const kpis = await analyticsService.getKPIs();
    res.json({ success: true, data: { kpis } });
});

exports.getMonthlyStats = asyncHandler(async (req, res) => {
    const months = parseInt(req.query.months, 10) || 12;
    const stats = await analyticsService.getMonthlyStats(months);
    res.json({ success: true, data: { stats } });
});

exports.getRoleDistribution = asyncHandler(async (_req, res) => {
    const distribution = await analyticsService.getRoleDistribution();
    res.json({ success: true, data: { distribution } });
});

exports.getTopEvents = asyncHandler(async (req, res) => {
    const limit = parseInt(req.query.limit, 10) || 10;
    const events = await analyticsService.getTopEvents(limit);
    res.json({ success: true, data: { events } });
});

exports.getApplicationStatusDistribution = asyncHandler(async (_req, res) => {
    const distribution = await analyticsService.getApplicationStatusDistribution();
    res.json({ success: true, data: { distribution } });
});

exports.getEventStatusDistribution = asyncHandler(async (_req, res) => {
    const distribution = await analyticsService.getEventStatusDistribution();
    res.json({ success: true, data: { distribution } });
});
