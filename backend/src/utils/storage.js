const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const {
    S3Client,
    PutObjectCommand,
    DeleteObjectCommand,
    GetObjectCommand,
} = require('@aws-sdk/client-s3');
const { getSignedUrl: s3GetSignedUrl } = require('@aws-sdk/s3-request-presigner');
const config = require('../config');

// ─── S3 Client (lazy init) ──────────────────────
let s3Client;
const getS3Client = () => {
    if (!s3Client) {
        const s3Config = {
            region: config.storage.s3.region,
            credentials: {
                accessKeyId: config.storage.s3.accessKeyId,
                secretAccessKey: config.storage.s3.secretAccessKey,
            },
        };
        if (config.storage.s3.endpoint) {
            s3Config.endpoint = config.storage.s3.endpoint;
            s3Config.forcePathStyle = true; // Required for MinIO
        }
        s3Client = new S3Client(s3Config);
    }
    return s3Client;
};

// ─── Ensure local upload dirs exist ─────────────
const ensureDir = (dir) => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
};

/**
 * Upload a file.
 * @param {Buffer} fileBuffer
 * @param {string} originalName
 * @param {string} folder - e.g. 'avatars', 'cvs', 'events'
 * @param {string} mimeType
 * @returns {Promise<string>} - stored file path/key
 */
const uploadFile = async (fileBuffer, originalName, folder, mimeType) => {
    const ext = path.extname(originalName);
    const filename = `${folder}/${uuidv4()}${ext}`;

    if (config.storage.type === 's3') {
        const command = new PutObjectCommand({
            Bucket: config.storage.s3.bucket,
            Key: filename,
            Body: fileBuffer,
            ContentType: mimeType,
        });
        await getS3Client().send(command);
        return filename;
    }

    // Local storage
    const dir = path.join(config.storage.localDir, folder);
    ensureDir(dir);
    const filePath = path.join(config.storage.localDir, filename);
    fs.writeFileSync(filePath, fileBuffer);
    return filename;
};

/**
 * Delete a file.
 * @param {string} fileKey - path/key from uploadFile
 */
const deleteFile = async (fileKey) => {
    if (!fileKey) return;

    if (config.storage.type === 's3') {
        const command = new DeleteObjectCommand({
            Bucket: config.storage.s3.bucket,
            Key: fileKey,
        });
        await getS3Client().send(command);
        return;
    }

    // Local
    const filePath = path.join(config.storage.localDir, fileKey);
    if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
    }
};

/**
 * Get a signed/temporary URL for private files (e.g. CVs).
 * For local storage, returns a relative path (serve via route).
 * @param {string} fileKey
 * @param {number} expiresIn - seconds (default 15 min)
 */
const getSignedUrl = async (fileKey, expiresIn = 900) => {
    if (!fileKey) return null;

    if (config.storage.type === 's3') {
        const command = new GetObjectCommand({
            Bucket: config.storage.s3.bucket,
            Key: fileKey,
        });
        return s3GetSignedUrl(getS3Client(), command, { expiresIn });
    }

    // For local, we return the API path — auth middleware will protect it
    return `/api/upload/file/${fileKey}`;
};

/**
 * Get a public URL for files like avatars and event images.
 * @param {string} fileKey
 */
const getPublicUrl = (fileKey) => {
    if (!fileKey) return null;

    if (config.storage.type === 's3') {
        const endpoint = config.storage.s3.endpoint || `https://s3.${config.storage.s3.region}.amazonaws.com`;
        return `${endpoint}/${config.storage.s3.bucket}/${fileKey}`;
    }

    return `/uploads/${fileKey}`;
};

module.exports = {
    uploadFile,
    deleteFile,
    getSignedUrl,
    getPublicUrl,
};
