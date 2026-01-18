database/schema/001_init.sql

-- =========================
-- USERS & AUTH
-- =========================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE role_permissions (
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- =========================
-- CORE BUSINESS
-- =========================

CREATE TABLE destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    country TEXT NOT NULL,
    description TEXT
);

CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    destination_id UUID REFERENCES destinations(id),
    host_id UUID REFERENCES users(id),
    base_price NUMERIC NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    capacity INT NOT NULL
);

CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    trip_id UUID REFERENCES trips(id),
    status TEXT CHECK (status IN ('pending','confirmed','cancelled')),
    final_price NUMERIC,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES bookings(id),
    amount NUMERIC NOT NULL,
    status TEXT CHECK (status IN ('pending','success','failed')),
    provider TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    trip_id UUID REFERENCES trips(id),
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT now()
);

-- =========================
-- RBAC SEED DATA
-- =========================

INSERT INTO roles (name) VALUES
('admin'),
('host'),
('traveler');

INSERT INTO permissions (name) VALUES
('CREATE_TRIP'),
('EDIT_TRIP'),
('DELETE_TRIP'),
('BOOK_TRIP'),
('CANCEL_BOOKING'),
('VIEW_ALL_USERS');

-- Map roles to permissions

-- Admin = everything
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'admin';

-- Host permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name IN ('CREATE_TRIP','EDIT_TRIP','DELETE_TRIP')
WHERE r.name = 'host';

-- Traveler permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name IN ('BOOK_TRIP','CANCEL_BOOKING')
WHERE r.name = 'traveler';

ALTER TABLE bookings 
DROP CONSTRAINT bookings_status_check;

ALTER TABLE bookings
ADD CONSTRAINT bookings_status_check
CHECK (status IN ('pending','confirmed','cancelled'));

ALTER TABLE bookings
ALTER COLUMN user_id SET NOT NULL,
ALTER COLUMN trip_id SET NOT NULL;

ALTER TABLE payments
ALTER COLUMN booking_id SET NOT NULL;

INSERT INTO roles (name) VALUES ('admin'), ('host'), ('traveler');

INSERT INTO permissions (name) VALUES
('CREATE_TRIP'),('EDIT_TRIP'),('DELETE_TRIP'),
('BOOK_TRIP'),('CANCEL_BOOKING'),('VIEW_ALL_USERS');