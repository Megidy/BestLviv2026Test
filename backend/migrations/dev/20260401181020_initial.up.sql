CREATE TYPE request_priority AS ENUM ('normal', 'elevated', 'critical', 'urgent');
CREATE TYPE allocation_status AS ENUM('planned', 'approved', 'in_transit', 'delivered', 'cancelled');
CREATE TYPE request_status AS ENUM ('pending', 'allocated', 'in_transit', 'delivered', 'cancelled');
CREATE TYPE user_role AS ENUM ('worker', 'admin');
CREATE TYPE customer_type AS ENUM ('shop', 'mall');

CREATE TABLE warehouses (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type customer_type NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    warehouse_id BIGINT REFERENCES warehouses(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE resources (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    unit_measure VARCHAR(50),
    logo_uri TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE inventories (
    id BIGSERIAL PRIMARY KEY,
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    resource_id BIGINT NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (warehouse_id, resource_id)
);

CREATE TABLE delivery_requests (
    id BIGSERIAL PRIMARY KEY,
    destination_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    resource_id BIGINT NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION NOT NULL,
    priority request_priority NOT NULL,
    status request_status NOT NULL,
    arrive_till TIMESTAMPTZ
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE delivery_request_items (
    id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES delivery_requests(id) ON DELETE CASCADE,
    resource_id BIGINT NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()

    UNIQUE (request_id, resource_id)
);

CREATE TABLE allocations (
    id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES delivery_requests(id) ON DELETE CASCADE,
    source_warehouse_id BIGINT NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION NOT NULL,
    allocation_status allocation_status NOT NULL, 
    dispatched_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION update_timestamp_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_timestamp_warehouses
BEFORE UPDATE ON warehouses FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TRIGGER set_timestamp_customers
BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

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