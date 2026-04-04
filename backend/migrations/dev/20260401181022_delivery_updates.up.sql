-- Add resource_id to allocations so each allocation row tracks which resource it covers
ALTER TABLE allocations ADD COLUMN resource_id BIGINT REFERENCES resources(id) ON DELETE CASCADE;

-- Add DISPATCHER role to the enum (was missing)
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'dispatcher';
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'admin';

-- Add urgent to priority enum (was missing from Go constants, exists in DB)
-- (urgent already exists from initial schema)
