-- ============================================================
-- Vary delivery requests and allocations for demo realism.
-- Adds 12 new delivery requests across different cities,
-- priorities, statuses, and resource types.
-- ============================================================

-- -------------------------------------------------------
-- New delivery requests
-- -------------------------------------------------------
INSERT INTO delivery_requests (destination_id, resource_id, user_id, quantity, priority, status, arrive_till, created_at, updated_at) VALUES
  -- Delivered
  (2,  1,  1, 40,  'normal',   'delivered',  NOW() - INTERVAL '6 days',    NOW() - INTERVAL '8 days',       NOW() - INTERVAL '6 days'),
  (9,  8,  3, 60,  'elevated', 'delivered',  NOW() - INTERVAL '4 days',    NOW() - INTERVAL '5 days',       NOW() - INTERVAL '4 days'),
  (17, 4,  5, 25,  'normal',   'delivered',  NOW() - INTERVAL '2 days',    NOW() - INTERVAL '3 days',       NOW() - INTERVAL '2 days'),
  -- In transit
  (5,  3,  1, 80,  'elevated', 'in_transit', NOW() + INTERVAL '8 hours',   NOW() - INTERVAL '25 hours',     NOW() - INTERVAL '12 hours'),
  (11, 9,  3, 15,  'normal',   'in_transit', NOW() + INTERVAL '3 hours',   NOW() - INTERVAL '19 hours',     NOW() - INTERVAL '10 hours'),
  -- Allocated
  (7,  14, 5, 120, 'elevated', 'allocated',  NOW() + INTERVAL '1 day',     NOW() - INTERVAL '11 hours',     NOW() - INTERVAL '11 hours'),
  (20, 11, 1, 50,  'normal',   'allocated',  NOW() + INTERVAL '2 days',    NOW() - INTERVAL '7 hours',      NOW() - INTERVAL '7 hours'),
  -- Pending
  (13, 18, 3, 200, 'critical', 'pending',    NOW() + INTERVAL '4 hours',   NOW() - INTERVAL '2 hours',      NOW() - INTERVAL '2 hours'),
  (25, 5,  5, 30,  'normal',   'pending',    NOW() + INTERVAL '3 days',    NOW() - INTERVAL '61 minutes',   NOW() - INTERVAL '61 minutes'),
  (33, 21, 1, 10,  'urgent',   'pending',    NOW() + INTERVAL '1 hour',    NOW() - INTERVAL '31 minutes',   NOW() - INTERVAL '31 minutes'),
  -- Cancelled
  (15, 10, 3, 45,  'elevated', 'cancelled',  NULL,                          NOW() - INTERVAL '3 days',       NOW() - INTERVAL '2 days'),
  (6,  2,  5, 20,  'normal',   'cancelled',  NULL,                          NOW() - INTERVAL '5 days',       NOW() - INTERVAL '4 days');

-- -------------------------------------------------------
-- Items: one per new request.
-- ON CONFLICT DO NOTHING guards against re-runs or
-- overlap with items from the previous migration.
-- -------------------------------------------------------
INSERT INTO delivery_request_items (request_id, resource_id, quantity, created_at, updated_at)
SELECT dr.id, dr.resource_id, dr.quantity, dr.created_at, dr.updated_at
FROM delivery_requests dr
WHERE dr.created_at > NOW() - INTERVAL '9 days'
  AND dr.status IN ('delivered', 'in_transit', 'allocated', 'pending', 'cancelled')
ON CONFLICT (request_id, resource_id) DO NOTHING;

-- -------------------------------------------------------
-- Allocations: only for requests that don't already have one.
-- -------------------------------------------------------

-- Delivered — source warehouse 2
INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
SELECT dr.id, 2, dr.resource_id, dr.quantity, 'delivered', dr.arrive_till, dr.created_at, dr.updated_at
FROM delivery_requests dr
WHERE dr.status = 'delivered'
  AND dr.created_at > NOW() - INTERVAL '9 days'
  AND NOT EXISTS (SELECT 1 FROM allocations a WHERE a.request_id = dr.id);

-- In transit — pick warehouse by request id modulo
INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
SELECT dr.id,
  CASE (dr.id % 5) WHEN 0 THEN 3 WHEN 1 THEN 5 WHEN 2 THEN 6 WHEN 3 THEN 9 ELSE 12 END,
  dr.resource_id, dr.quantity, 'in_transit', NOW() - INTERVAL '6 hours', dr.created_at, dr.updated_at
FROM delivery_requests dr
WHERE dr.status = 'in_transit'
  AND dr.created_at > NOW() - INTERVAL '9 days'
  AND NOT EXISTS (SELECT 1 FROM allocations a WHERE a.request_id = dr.id);

-- Allocated — approved, awaiting dispatch
INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
SELECT dr.id,
  CASE (dr.id % 4) WHEN 0 THEN 4 WHEN 1 THEN 7 WHEN 2 THEN 10 ELSE 15 END,
  dr.resource_id, dr.quantity, 'approved', NULL, dr.created_at, dr.updated_at
FROM delivery_requests dr
WHERE dr.status = 'allocated'
  AND dr.created_at > NOW() - INTERVAL '9 days'
  AND NOT EXISTS (SELECT 1 FROM allocations a WHERE a.request_id = dr.id);

-- Critical pending — split across 3 warehouses
INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
SELECT dr.id, w.wh_id, dr.resource_id,
  CASE w.wh_id WHEN 1 THEN 80 WHEN 5 THEN 70 ELSE 50 END,
  'planned', NULL, dr.created_at, dr.updated_at
FROM delivery_requests dr
CROSS JOIN (VALUES (1), (5), (8)) AS w(wh_id)
WHERE dr.status = 'pending' AND dr.priority = 'critical'
  AND dr.created_at > NOW() - INTERVAL '9 days'
  AND NOT EXISTS (SELECT 1 FROM allocations a WHERE a.request_id = dr.id);
