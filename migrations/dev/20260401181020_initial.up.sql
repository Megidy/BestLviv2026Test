CREATE TYPE request_priority AS ENUM ('normal', 'elevated', 'critical');
CREATE TYPE request_status AS ENUM ('pending', 'allocated', 'in_transit', 'delivered', 'cancelled');
CREATE TYPE user_role AS ENUM ('worker');

CREATE TABLE locations (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    location_id BIGINT REFERENCES locations(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE resources (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    unit_measure VARCHAR(50),
    logo_uri TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inventories (
    id BIGSERIAL PRIMARY KEY,
    location_id BIGINT NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    resource_id BIGINT NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE delivery_requests (
    id BIGSERIAL PRIMARY KEY,
    destination_id BIGINT NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    resource_id BIGINT NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION NOT NULL,
    priority request_priority NOT NULL,
    status request_status NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE allocations (
    id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES delivery_requests(id) ON DELETE CASCADE,
    source_location_id BIGINT NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION NOT NULL,
    status request_status NOT NULL,
    dispatched_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION update_timestamp_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_timestamp_locations
BEFORE UPDATE ON locations FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TRIGGER set_timestamp_resources
BEFORE UPDATE ON resources FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TRIGGER set_timestamp_inventories
BEFORE UPDATE ON inventories FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TRIGGER set_timestamp_delivery_requests
BEFORE UPDATE ON delivery_requests FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TRIGGER set_timestamp_allocations
BEFORE UPDATE ON allocations FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TRIGGER set_timestamp_users
BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE  INDEX idx_inventories_location ON inventories(location_id);
CREATE INDEX idx_inventories_resource ON inventories(resource_id);
CREATE INDEX idx_requests_destination ON delivery_requests(destination_id);
CREATE INDEX idx_requests_resource ON delivery_requests(resource_id);
CREATE INDEX idx_allocations_request ON allocations(request_id);
CREATE INDEX idx_allocations_source ON allocations(source_location_id);