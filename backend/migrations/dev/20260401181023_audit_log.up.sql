CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    actor_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    actor_role VARCHAR(50) NOT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id BIGINT,
    before_value JSONB,
    after_value JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_log_actor ON audit_log(actor_id);
CREATE INDEX idx_audit_log_action ON audit_log(action);
CREATE INDEX idx_audit_log_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at DESC);
