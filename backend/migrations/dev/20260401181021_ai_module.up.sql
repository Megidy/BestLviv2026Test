CREATE TYPE alert_status AS ENUM ('open', 'dismissed', 'resolved');
CREATE TYPE proposal_status AS ENUM ('pending', 'approved', 'dismissed');
CREATE TYPE demand_source AS ENUM ('manual', 'sensor', 'predicted');

CREATE TABLE demand_readings (
    id BIGSERIAL PRIMARY KEY,
    point_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    resource_id BIGINT NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source demand_source NOT NULL DEFAULT 'manual',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_demand_readings_lookup ON demand_readings(point_id, resource_id, recorded_at DESC);

CREATE TABLE rebalancing_proposals (
    id BIGSERIAL PRIMARY KEY,
    target_point_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    resource_id BIGINT NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    urgency VARCHAR(50) NOT NULL DEFAULT 'predictive',
    confidence DOUBLE PRECISION NOT NULL,
    status proposal_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rebalancing_transfers (
    id BIGSERIAL PRIMARY KEY,
    proposal_id BIGINT NOT NULL REFERENCES rebalancing_proposals(id) ON DELETE CASCADE,
    from_warehouse_id BIGINT NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION NOT NULL,
    estimated_arrival_hours DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE predictive_alerts (
    id BIGSERIAL PRIMARY KEY,
    point_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    resource_id BIGINT NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    predicted_shortfall_at TIMESTAMPTZ NOT NULL,
    confidence DOUBLE PRECISION NOT NULL,
    status alert_status NOT NULL DEFAULT 'open',
    proposal_id BIGINT REFERENCES rebalancing_proposals(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_predictive_alerts_status ON predictive_alerts(status);
CREATE INDEX idx_predictive_alerts_point ON predictive_alerts(point_id);

CREATE TRIGGER set_timestamp_rebalancing_proposals
BEFORE UPDATE ON rebalancing_proposals FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();

CREATE TRIGGER set_timestamp_predictive_alerts
BEFORE UPDATE ON predictive_alerts FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
