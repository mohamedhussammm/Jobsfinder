const Company = require('../models/Company');
const AppError = require('../utils/AppError');
const { parsePagination, paginationMeta } = require('../utils/pagination');

const createCompany = async (ownerId, data) => {
    // One company per owner
    const existing = await Company.findOne({ owner: ownerId });
    if (existing) throw new AppError('You already have a company profile', 400);

    const company = await Company.create({ ...data, owner: ownerId });
    return company;
};

const getAllCompanies = async (query) => {
    const { skip, limit, page } = parsePagination(query);
    const filter = {};
    if (query.search) {
        filter.name = { $regex: query.search, $options: 'i' };
    }

    const [companies, total] = await Promise.all([
        Company.find(filter).populate('owner', 'name email').skip(skip).limit(limit).sort({ createdAt: -1 }),
        Company.countDocuments(filter),
    ]);

    return { companies, pagination: paginationMeta(total, page, limit) };
};

const getCompanyById = async (id) => {
    const company = await Company.findById(id).populate('owner', 'name email');
    if (!company) throw new AppError('Company not found', 404);
    return company;
};

const getCompanyByOwner = async (ownerId) => {
    const company = await Company.findOne({ owner: ownerId });
    return company;
};

const updateCompany = async (id, userId, userRole, data) => {
    const company = await Company.findById(id);
    if (!company) throw new AppError('Company not found', 404);

    // Only owner or admin can update
    if (company.owner.toString() !== userId && userRole !== 'admin') {
        throw new AppError('Not authorized to update this company', 403);
    }

    Object.assign(company, data);
    await company.save();
    return company;
};

const verifyCompany = async (id) => {
    const company = await Company.findByIdAndUpdate(id, { verified: true }, { new: true });
    if (!company) throw new AppError('Company not found', 404);
    return company;
};

module.exports = {
    createCompany,
    getAllCompanies,
    getCompanyById,
    getCompanyByOwner,
    updateCompany,
    verifyCompany,
};
