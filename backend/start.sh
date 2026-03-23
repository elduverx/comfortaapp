#!/bin/bash

echo "🚀 ComfortaApp Backend - Quick Start"
echo "===================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    echo "Visit: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "⚠️  PostgreSQL is not installed."
    echo "Install PostgreSQL: https://www.postgresql.org/download/"
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
else
    echo "✅ Dependencies already installed"
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
    echo "📝 Please edit .env file with your database credentials"
    echo "   nano .env"
    exit 0
fi

echo "✅ .env file found"

# Check if database is accessible
echo "🔍 Checking database connection..."

# Try to connect to database
if psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" &> /dev/null; then
    echo "✅ Database connection successful"
else
    echo "⚠️  Could not connect to database"
    echo "   Make sure PostgreSQL is running and credentials in .env are correct"
    echo ""
    echo "   To create database:"
    echo "   psql -U postgres"
    echo "   CREATE DATABASE comfortaapp;"
    echo "   CREATE USER comfortaapp_user WITH PASSWORD 'your_password';"
    echo "   GRANT ALL PRIVILEGES ON DATABASE comfortaapp TO comfortaapp_user;"
    echo ""
    echo "   Then run migrations:"
    echo "   psql -U comfortaapp_user -d comfortaapp -f src/database/schema.sql"
fi

echo ""
echo "🎉 Ready to start!"
echo ""
echo "Development mode:"
echo "  npm run dev"
echo ""
echo "Production mode:"
echo "  npm start"
echo ""
