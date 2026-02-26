/**
 * Parse pagination params from query string.
 * Usage: const { skip, limit, page } = parsePagination(req.query);
 */
const parsePagination = (query) => {
    const page = Math.max(parseInt(query.page, 10) || 1, 1);
    const limit = Math.min(Math.max(parseInt(query.limit, 10) || 10, 1), 100);
    const skip = (page - 1) * limit;
    return { page, limit, skip };
};

/**
 * Build pagination metadata to include in response.
 */
const paginationMeta = (total, page, limit) => {
    const totalPages = Math.ceil(total / limit);
    return {
        total,
        page,
        limit,
        totalPages,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1,
    };
};

module.exports = { parsePagination, paginationMeta };
