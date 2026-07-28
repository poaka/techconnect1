const multer = require('multer');
const { ApiError } = require('./errorHandler');

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(ApiError.badRequest('Type de fichier non autorisé. Formats acceptés: JPEG, PNG, WEBP, PDF'), false);
  }
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB maximum file size
  },
  fileFilter: fileFilter
});

module.exports = upload;
