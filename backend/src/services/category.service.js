const Category = require('../models/Category');
const AppError = require('../utils/AppError');

const createCategory = async (data) => {
    const category = await Category.create(data);
    return category;
};

const getAllCategories = async () => {
    return Category.find().sort({ name: 1 });
};

const updateCategory = async (id, data) => {
    const category = await Category.findByIdAndUpdate(id, data, { new: true, runValidators: true });
    if (!category) throw new AppError('Category not found', 404);
    return category;
};

const deleteCategory = async (id) => {
    const category = await Category.findByIdAndDelete(id);
    if (!category) throw new AppError('Category not found', 404);
    return category;
};

module.exports = { createCategory, getAllCategories, updateCategory, deleteCategory };
