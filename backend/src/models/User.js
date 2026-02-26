const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
    {
        email: {
            type: String,
            required: [true, 'Email is required'],
            unique: true,
            lowercase: true,
            trim: true,
        },
        password: {
            type: String,
            minlength: [8, 'Password must be at least 8 characters'],
            select: false, // Never return password by default
            // Not required — Google OAuth users don't have a password
        },
        googleId: {
            type: String,
            unique: true,
            sparse: true,
        },
        authProvider: {
            type: String,
            enum: ['local', 'google'],
            default: 'local',
        },
        name: {
            type: String,
            trim: true,
        },
        role: {
            type: String,
            enum: ['normal', 'company', 'team_leader', 'admin'],
            default: 'normal',
        },
        phone: {
            type: String,
            trim: true,
        },
        nationalIdNumber: {
            type: String,
            unique: true,
            sparse: true, // allows multiple nulls
            trim: true,
        },
        avatarPath: {
            type: String,
        },
        profileComplete: {
            type: Boolean,
            default: false,
        },
        ratingAvg: {
            type: Number,
            default: 0,
            min: 0,
            max: 5,
        },
        ratingCount: {
            type: Number,
            default: 0,
        },

        // ─── Auth Fields ────────────────────────
        emailVerified: {
            type: Boolean,
            default: false,
        },
        emailVerifyToken: String,
        emailVerifyExpires: Date,

        passwordResetToken: String,
        passwordResetExpires: Date,

        refreshTokens: [
            {
                token: String,
                createdAt: { type: Date, default: Date.now },
            },
        ],

        // ─── Soft Delete ────────────────────────
        deletedAt: {
            type: Date,
            default: null,
        },
    },
    {
        timestamps: true, // createdAt, updatedAt
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

// ─── Indexes ────────────────────────────────────
userSchema.index({ email: 1 });
userSchema.index({ role: 1 });
userSchema.index({ nationalIdNumber: 1 });

// ─── Pre-save: Hash password ────────────────────
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
});

// ─── Instance Method: Compare passwords ─────────
userSchema.methods.comparePassword = async function (candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
};

// ─── Remove sensitive fields from JSON output ───
userSchema.methods.toJSON = function () {
    const user = this.toObject();
    delete user.password;
    delete user.refreshTokens;
    delete user.emailVerifyToken;
    delete user.emailVerifyExpires;
    delete user.passwordResetToken;
    delete user.passwordResetExpires;
    delete user.__v;
    return user;
};

module.exports = mongoose.model('User', userSchema);
