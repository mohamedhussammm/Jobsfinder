const User = require('../models/User');
const AppError = require('../utils/AppError');
const { parsePagination, paginationMeta } = require('../utils/pagination');

/**
 * Get all users (admin).
 */
const getAllUsers = async (query) => {
    const { skip, limit, page } = parsePagination(query);
    const filter = {};

    if (query.role) filter.role = query.role;
    if (query.search) {
        filter.$or = [
            { name: { $regex: query.search, $options: 'i' } },
            { email: { $regex: query.search, $options: 'i' } },
        ];
    }

    const [users, total] = await Promise.all([
        User.find(filter).skip(skip).limit(limit).sort({ createdAt: -1 }),
        User.countDocuments(filter),
    ]);

    return { users, pagination: paginationMeta(total, page, limit) };
};

/**
 * Get user by ID.
 */
const getUserById = async (userId) => {
    const user = await User.findById(userId);
    if (!user) throw new AppError('User not found', 404);
    return user;
};

/**
 * Update own profile.
 */
const updateProfile = async (userId, data) => {
    const user = await User.findByIdAndUpdate(userId, data, {
        new: true,
        runValidators: true,
    });
    if (!user) throw new AppError('User not found', 404);
    return user;
};

/**
 * Block a user (admin).
 */
const blockUser = async (userId) => {
    const user = await User.findById(userId);
    if (!user) throw new AppError('User not found', 404);
    if (user.role === 'admin') throw new AppError('Cannot block admin users', 400);

    user.deletedAt = new Date();
    user.refreshTokens = []; // Force logout
    await user.save({ validateBeforeSave: false });
    return user;
};

/**
 * Unblock a user (admin).
 */
const unblockUser = async (userId) => {
    const user = await User.findById(userId);
    if (!user) throw new AppError('User not found', 404);

    user.deletedAt = null;
    await user.save({ validateBeforeSave: false });
    return user;
};

/**
 * Get user count by role.
 */
const getUserCountByRole = async () => {
    const counts = await User.aggregate([
        { $group: { _id: '$role', count: { $sum: 1 } } },
    ]);
    const result = {};
    counts.forEach((c) => { result[c._id] = c.count; });
    return result;
};

/**
 * Change user role (admin).
 */
const changeRole = async (userId, role) => {
    const VALID_ROLES = ['admin', 'company', 'team_leader', 'normal'];
    if (!VALID_ROLES.includes(role)) throw new AppError('Invalid role', 400);
    const user = await User.findByIdAndUpdate(
        userId,
        { role },
        { new: true, runValidators: true }
    );
    if (!user) throw new AppError('User not found', 404);
    return user;
};

module.exports = {
    getAllUsers,
    getUserById,
    updateProfile,
    blockUser,
    unblockUser,
    getUserCountByRole,
    changeRole,
};
