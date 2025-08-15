const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../config/config');
const router = express.Router();

// Simple admin user for demo (in production, use database)
const ADMIN_USER = {
  username: 'admin',
  password: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
  role: 'admin'
};

// Check if user is already authenticated
const checkAuth = (req, res, next) => {
  if (req.session.user) {
    res.redirect('/');
  } else {
    next();
  }
};

// Login page
router.get('/login', checkAuth, (req, res) => {
  res.render('auth/login', { 
    title: 'Login',
    config
  });
});

// Login process
router.post('/login', checkAuth, async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      req.flash('error_msg', 'Username and password are required');
      return res.redirect('/auth/login');
    }

    // Check if user exists and password is correct
    if (username === ADMIN_USER.username && await bcrypt.compare(password, ADMIN_USER.password)) {
      req.session.user = {
        id: 1,
        username: ADMIN_USER.username,
        role: ADMIN_USER.role
      };
      
      req.flash('success_msg', 'Welcome back!');
      res.redirect('/');
    } else {
      req.flash('error_msg', 'Invalid username or password');
      res.redirect('/auth/login');
    }
  } catch (error) {
    console.error('Login error:', error);
    req.flash('error_msg', 'Login failed');
    res.redirect('/auth/login');
  }
});

// Logout
router.get('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      console.error('Logout error:', err);
    }
    res.redirect('/auth/login');
  });
});

// Change password page
router.get('/change-password', (req, res) => {
  if (!req.session.user) {
    return res.redirect('/auth/login');
  }
  
  res.render('auth/change-password', { 
    title: 'Change Password',
    user: req.session.user,
    config
  });
});

// Change password process
router.post('/change-password', async (req, res) => {
  if (!req.session.user) {
    return res.redirect('/auth/login');
  }

  try {
    const { currentPassword, newPassword, confirmPassword } = req.body;
    
    if (!currentPassword || !newPassword || !confirmPassword) {
      req.flash('error_msg', 'All fields are required');
      return res.redirect('/auth/change-password');
    }

    if (newPassword !== confirmPassword) {
      req.flash('error_msg', 'New passwords do not match');
      return res.redirect('/auth/change-password');
    }

    if (newPassword.length < 6) {
      req.flash('error_msg', 'Password must be at least 6 characters long');
      return res.redirect('/auth/change-password');
    }

    // Verify current password
    if (!(await bcrypt.compare(currentPassword, ADMIN_USER.password))) {
      req.flash('error_msg', 'Current password is incorrect');
      return res.redirect('/auth/change-password');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // In production, update password in database
    // For demo, we'll just show success message
    req.flash('success_msg', 'Password changed successfully');
    res.redirect('/');
    
  } catch (error) {
    console.error('Change password error:', error);
    req.flash('error_msg', 'Failed to change password');
    res.redirect('/auth/change-password');
  }
});

module.exports = router;
