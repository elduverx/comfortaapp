-- ComfortaApp Database Schema
-- PostgreSQL

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    phone VARCHAR(50),
    apple_user_id VARCHAR(255) UNIQUE,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin', 'driver')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trips Table
CREATE TABLE IF NOT EXISTS trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    pickup_location TEXT,
    destination TEXT NOT NULL,
    pickup_lat DECIMAL(10, 8),
    pickup_lng DECIMAL(11, 8),
    destination_lat DECIMAL(10, 8),
    destination_lng DECIMAL(11, 8),
    distance_km DECIMAL(10, 2),
    base_price DECIMAL(10, 2),
    airport_surcharge DECIMAL(10, 2) DEFAULT 0,
    total_price DECIMAL(10, 2),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELED', 'COMPLETED', 'EXPIRED')),
    driver_id VARCHAR(255),
    driver_name VARCHAR(255),
    payment_method VARCHAR(50) DEFAULT 'CASH',
    payment_order_id VARCHAR(255),
    payment_date TIMESTAMP,
    paid BOOLEAN DEFAULT FALSE,
    invoice_number VARCHAR(100),
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    time_slot VARCHAR(100),
    notes TEXT,
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Device Tokens for Push Notifications
CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) CHECK (platform IN ('ios', 'android')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_trips_user_id ON trips(user_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_created_at ON trips(created_at);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON trips
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
