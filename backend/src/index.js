const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const env = require('./config/env');
const { errorHandler, ApiError } = require('./middleware/errorHandler');

// Route imports
const authRoutes = require('./routes/auth.routes');
const techniciansRoutes = require('./routes/technicians.routes');
const requestsRoutes = require('./routes/requests.routes');
const reviewsRoutes = require('./routes/reviews.routes');
const favoritesRoutes = require('./routes/favorites.routes');
const notificationsRoutes = require('./routes/notifications.routes');
const adminRoutes = require('./routes/admin.routes');

const app = express();

// Security and utility middlewares
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: env.corsOrigin }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static admin dashboard
app.use('/admin/public', express.static(path.join(__dirname, '../public')));
app.get('/admin/verify', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/admin.html'));
});

// Root welcome route
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'Bienvenue sur l\'API TechConnect Cameroun',
    health: '/health',
    version: '1.0.0'
  });
});

// One-time admin seed/reset (development only – remove in production)
app.get('/setup-admin', async (req, res) => {
  const supabase = require('./config/supabase');
  const bcrypt = require('bcryptjs');
  if (!supabase) {
    return res.json({ ok: false, message: 'Supabase not connected (running in local mode). Admin mock user is available.' });
  }
  try {
    const hash = await bcrypt.hash('Password123!', 10);
    const { data, error } = await supabase
      .from('users')
      .upsert([{
        full_name: 'Admin TechConnect',
        email: 'admin@techconnect.cm',
        phone: '+237690000000',
        password_hash: hash,
        role: 'admin'
      }], { onConflict: 'email' })
      .select('id, email, role')
      .single();

    if (error) {
      return res.json({ ok: false, error: error.message, details: error });
    }
    return res.json({ ok: true, message: '✅ Admin upserted successfully!', user: data });
  } catch (err) {
    return res.json({ ok: false, error: err.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    env: env.nodeEnv,
    service: 'TechConnect Cameroun REST API'
  });
});

// API Routes (all 7 modules)
app.use('/api/auth', authRoutes);
app.use('/api/technicians', techniciansRoutes);
app.use('/api/requests', requestsRoutes);
app.use('/api/reviews', reviewsRoutes);
app.use('/api/favorites', favoritesRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/admin', adminRoutes);

// 404 Handler
app.use((req, res, next) => {
  next(ApiError.notFound(`Route '${req.originalUrl}' non trouvée`));
});

// Centralized error handler
app.use(errorHandler);

// Start server if run directly
if (require.main === module) {
  app.listen(env.port, () => {
    console.log(`\n=================================================`);
    console.log(`🚀 TechConnect Cameroun API Backend en cours d'exécution`);
    console.log(`📍 URL: http://localhost:${env.port}`);
    console.log(`🏥 Health Check: http://localhost:${env.port}/health`);
    console.log(`🛠️  Admin Verification Stand-in: http://localhost:${env.port}/admin/verify`);
    console.log(`=================================================\n`);
  });
}

module.exports = app;
