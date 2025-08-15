#!/bin/bash

# Headscale Admin Dashboard Startup Script

echo "🚀 Starting Headscale Admin Dashboard..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 16+ first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cp env.example .env
    echo "📝 Please edit .env file with your configuration before starting."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start the application
echo "🌟 Starting application on port 3001..."
echo "📊 Dashboard: http://localhost:3001"
echo "🔗 Headscale API: $(grep HEADSCALE_URL .env | cut -d'=' -f2)"
echo ""
echo "Press Ctrl+C to stop the application"

# Start the application
if [ "$1" = "dev" ]; then
    npm run dev
else
    npm start
fi
