DROP TRIGGER IF EXISTS set_timestamp_predictive_alerts ON predictive_alerts;
DROP TRIGGER IF EXISTS set_timestamp_rebalancing_proposals ON rebalancing_proposals;
DROP TABLE IF EXISTS predictive_alerts;
DROP TABLE IF EXISTS rebalancing_transfers;
DROP TABLE IF EXISTS rebalancing_proposals;
DROP TABLE IF EXISTS demand_readings;
DROP TYPE IF EXISTS demand_source;
DROP TYPE IF EXISTS proposal_status;
DROP TYPE IF EXISTS alert_status;
