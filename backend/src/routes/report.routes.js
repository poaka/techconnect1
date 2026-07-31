const express = require('express');
const router = express.Router();
const ReportController = require('../controllers/report.controller');
const { requireAuth, requireRole } = require('../middleware/auth');

// Clients can report a technician
router.post('/', requireAuth, ReportController.createReport);

// Admins can manage reports
router.get('/admin', requireAuth, requireRole('admin'), ReportController.getReports);
router.patch('/admin/:id/resolve', requireAuth, requireRole('admin'), ReportController.resolveReport);

module.exports = router;
