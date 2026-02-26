const asyncHandler = require('../utils/asyncHandler');
const applicationService = require('../services/application.service');

exports.getAllApplications = asyncHandler(async (req, res) => {
    const result = await applicationService.getAllApplications(req.query);
    res.json({ success: true, data: result });
});

exports.applyToEvent = asyncHandler(async (req, res) => {
    const application = await applicationService.applyToEvent(req.user._id, req.body);
    res.status(201).json({ success: true, data: { application } });
});

exports.getMyApplications = asyncHandler(async (req, res) => {
    const result = await applicationService.getUserApplications(req.user._id, req.query);
    res.json({ success: true, data: result });
});

exports.getEventApplications = asyncHandler(async (req, res) => {
    const result = await applicationService.getEventApplications(req.params.eventId, req.query);
    res.json({ success: true, data: result });
});

exports.getApplicationById = asyncHandler(async (req, res) => {
    const application = await applicationService.getApplicationById(req.params.id);
    res.json({ success: true, data: { application } });
});

exports.updateApplicationStatus = asyncHandler(async (req, res) => {
    const application = await applicationService.updateApplicationStatus(
        req.params.id, req.body.status, req.user._id
    );
    res.json({ success: true, data: { application } });
});

exports.withdrawApplication = asyncHandler(async (req, res) => {
    await applicationService.withdrawApplication(req.params.id, req.user._id.toString());
    res.json({ success: true, message: 'Application withdrawn' });
});

exports.getApplicationStats = asyncHandler(async (_req, res) => {
    const stats = await applicationService.getApplicationStatsByStatus();
    res.json({ success: true, data: { stats } });
});
