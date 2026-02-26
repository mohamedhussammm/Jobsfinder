const asyncHandler = require('../utils/asyncHandler');
const categoryService = require('../services/category.service');

exports.createCategory = asyncHandler(async (req, res) => {
    const category = await categoryService.createCategory(req.body);
    res.status(201).json({ success: true, data: { category } });
});

exports.getAllCategories = asyncHandler(async (_req, res) => {
    const categories = await categoryService.getAllCategories();
    res.json({ success: true, data: { categories } });
});

exports.updateCategory = asyncHandler(async (req, res) => {
    const category = await categoryService.updateCategory(req.params.id, req.body);
    res.json({ success: true, data: { category } });
});

exports.deleteCategory = asyncHandler(async (req, res) => {
    await categoryService.deleteCategory(req.params.id);
    res.json({ success: true, message: 'Category deleted' });
});
