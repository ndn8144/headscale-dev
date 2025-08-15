const express = require('express');
const session = require('express-session');
const flash = require('connect-flash');
const path = require('path');
const http = require('http');
const socketIo = require('socket.io');
const config = require('./config/config');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// View engine setup (must come before routes)
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Session configuration (must come before flash)
app.use(session({
  secret: config.security.sessionSecret,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 } // 24 hours
}));

app.use(flash());

// Global variables (after session and flash)
app.use((req, res, next) => {
  res.locals.success_msg = req.flash('success_msg');
  res.locals.error_msg = req.flash('error_msg');
  res.locals.error = req.flash('error');
  next();
});

// Routes
const dashboardRoutes = require('./routes/dashboard');
const nodesRoutes = require('./routes/nodes');
const usersRoutes = require('./routes/users');
const apiRoutes = require('./routes/api');
const authRoutes = require('./routes/auth');

app.use('/', dashboardRoutes);
app.use('/nodes', nodesRoutes);
app.use('/users', usersRoutes);
app.use('/api', apiRoutes);
app.use('/auth', authRoutes);

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send(`
    <h1>Something went wrong!</h1>
    <p>${err.message}</p>
    <a href="/">Go back to dashboard</a>
  `);
});

// 404 handler
app.use((req, res) => {
  res.status(404).send(`
    <h1>Page Not Found</h1>
    <p>The page you are looking for does not exist.</p>
    <a href="/">Go back to dashboard</a>
  `);
});

// Start server
const PORT = config.server.port;
server.listen(PORT, () => {
  console.log(`🚀 Headscale Admin Dashboard running on port ${PORT}`);
  console.log(`📊 Dashboard: http://localhost:${PORT}`);
  console.log(`🔗 Headscale API: ${config.headscale.url}`);
});

module.exports = { app, server, io };
