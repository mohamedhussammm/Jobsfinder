const asyncHandler = require('../utils/asyncHandler');
const companyService = require('../services/company.service');
const auditLogService = require('../services/auditLog.service');

exports.createCompany = asyncHandler(async (req, res) => {
    const company = await companyService.createCompany(req.user._id, req.body);
    res.status(201).json({ success: true, data: { company } });
});

exports.getAllCompanies = asyncHandler(async (req, res) => {
    const result = await companyService.getAllCompanies(req.query);
    res.json({ success: true, data: result });
});

exports.getCompanyById = asyncHandler(async (req, res) => {
    const company = await companyService.getCompanyById(req.params.id);
    res.json({ success: true, data: { company } });
});

exports.getMyCompany = asyncHandler(async (req, res) => {
    const company = await companyService.getCompanyByOwner(req.user._id);
    res.json({ success: true, data: { company } });
});

exports.updateCompany = asyncHandler(async (req, res) => {
    const company = await companyService.updateCompany(
        req.params.id, req.user._id.toString(), req.user.role, req.body
    );
    res.json({ success: true, data: { company } });
});

exports.verifyCompany = asyncHandler(async (req, res) => {
    const company = await companyService.verifyCompany(req.params.id);
    await auditLogService.createLog({
        adminUserId: req.user._id,
        action: 'company_verified',
        targetTable: 'companies',
        targetId: company._id,
        newValues: { verified: true },
        ipAddress: req.ip,
    });
    res.json({ success: true, data: { company }, message: 'Company verified' });
});
