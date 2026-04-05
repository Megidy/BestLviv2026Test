-- ============================================================
-- Vary delivery requests and allocations for demo realism.
-- Uses CTEs to track newly inserted IDs — no cross-migration conflicts.
-- ============================================================

WITH new_requests AS (
  INSERT INTO delivery_requests (destination_id, resource_id, user_id, quantity, priority, status, arrive_till, created_at, updated_at) VALUES
    -- Delivered
    (2,  1,  1, 40,  'normal',   'delivered',  NOW() - INTERVAL '6 days',     NOW() - INTERVAL '8 days',       NOW() - INTERVAL '6 days'),
    (9,  8,  3, 60,  'elevated', 'delivered',  NOW() - INTERVAL '4 days',     NOW() - INTERVAL '5 days',       NOW() - INTERVAL '4 days'),
    (17, 4,  5, 25,  'normal',   'delivered',  NOW() - INTERVAL '2 days',     NOW() - INTERVAL '3 days',       NOW() - INTERVAL '2 days'),
    -- In transit
    (5,  3,  1, 80,  'elevated', 'in_transit', NOW() + INTERVAL '8 hours',    NOW() - INTERVAL '1 day',        NOW() - INTERVAL '12 hours'),
    (11, 9,  3, 15,  'normal',   'in_transit', NOW() + INTERVAL '3 hours',    NOW() - INTERVAL '18 hours',     NOW() - INTERVAL '10 hours'),
    -- Allocated
    (7,  14, 5, 120, 'elevated', 'allocated',  NOW() + INTERVAL '1 day',      NOW() - INTERVAL '10 hours',     NOW() - INTERVAL '10 hours'),
    (20, 11, 1, 50,  'normal',   'allocated',  NOW() + INTERVAL '2 days',     NOW() - INTERVAL '6 hours',      NOW() - INTERVAL '6 hours'),
    -- Pending
    (13, 18, 3, 200, 'critical', 'pending',    NOW() + INTERVAL '4 hours',    NOW() - INTERVAL '2 hours',      NOW() - INTERVAL '2 hours'),
    (25, 5,  5, 30,  'normal',   'pending',    NOW() + INTERVAL '3 days',     NOW() - INTERVAL '1 hour',       NOW() - INTERVAL '1 hour'),
    (33, 21, 1, 10,  'urgent',   'pending',    NOW() + INTERVAL '1 hour',     NOW() - INTERVAL '30 minutes',   NOW() - INTERVAL '30 minutes'),
    -- Cancelled
    (15, 10, 3, 45,  'elevated', 'cancelled',  NULL,                           NOW() - INTERVAL '3 days',       NOW() - INTERVAL '2 days'),
    (6,  2,  5, 20,  'normal',   'cancelled',  NULL,                           NOW() - INTERVAL '5 days',       NOW() - INTERVAL '4 days')
  RETURNING id, destination_id, resource_id, user_id, quantity, priority, status, arrive_till, created_at, updated_at
),

-- Items: one item per new request
new_items AS (
  INSERT INTO delivery_request_items (request_id, resource_id, quantity, created_at, updated_at)
  SELECT id, resource_id, quantity, created_at, updated_at
  FROM new_requests
  RETURNING request_id
),

-- Allocations for delivered requests
alloc_delivered AS (
  INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
  SELECT id, 2, resource_id, quantity, 'delivered', arrive_till, created_at, updated_at
  FROM new_requests
  WHERE status = 'delivered'
  RETURNING id
),

-- Allocations for in_transit requests
alloc_transit AS (
  INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
  SELECT id,
    CASE (id % 5) WHEN 0 THEN 3 WHEN 1 THEN 5 WHEN 2 THEN 6 WHEN 3 THEN 9 ELSE 12 END,
    resource_id, quantity, 'in_transit', NOW() - INTERVAL '6 hours', created_at, updated_at
  FROM new_requests
  WHERE status = 'in_transit'
  RETURNING id
),

-- Allocations for allocated requests (approved, awaiting dispatch)
alloc_approved AS (
  INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
  SELECT id,
    CASE (id % 4) WHEN 0 THEN 4 WHEN 1 THEN 7 WHEN 2 THEN 10 ELSE 15 END,
    resource_id, quantity, 'approved', NULL, created_at, updated_at
  FROM new_requests
  WHERE status = 'allocated'
  RETURNING id
),

-- Planned allocations split across 3 warehouses for the critical pending request
alloc_planned AS (
  INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
  SELECT nr.id, w.wh_id, nr.resource_id,
    CASE w.wh_id WHEN 1 THEN 80 WHEN 5 THEN 70 ELSE 50 END,
    'planned', NULL, nr.created_at, nr.updated_at
  FROM new_requests nr
  CROSS JOIN (VALUES (1), (5), (8)) AS w(wh_id)
  WHERE nr.status = 'pending' AND nr.priority = 'critical'
  RETURNING id
)

SELECT COUNT(*) AS inserted_requests FROM new_requests;
