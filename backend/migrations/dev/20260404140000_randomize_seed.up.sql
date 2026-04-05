-- ============================================================
-- Randomize seed: make inventory look realistic and varied.
-- Some warehouses out of certain resources, some with surpluses.
-- Add demand readings for new (point, resource) pairs.
-- Add historical delivery_requests with items and allocations.
-- ============================================================

-- ============================================================
-- Part 1: Inventory overrides
-- Zero-out 15 (warehouse, resource) pairs across categories
-- ============================================================

-- Food category: zero-outs
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 3  AND resource_id = 3;  -- Склад Харків — Олія соняшникова
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 7  AND resource_id = 5;  -- Склад Запоріжжя — Макарони
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 11 AND resource_id = 6;  -- Склад Миколаїв — Консерва м'ясна
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 14 AND resource_id = 4;  -- Склад Луцьк — Цукор
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 19 AND resource_id = 1;  -- Склад Хмельницький — Молоко

-- Medical category: zero-outs
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 4  AND resource_id = 19; -- Склад Одеса — Маска медична
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 9  AND resource_id = 21; -- Склад Полтава — Бинт стерильний
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 17 AND resource_id = 19; -- Склад Ужгород — Маска медична

-- Fuel category: zero-outs
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 2  AND resource_id = 18; -- Склад Київ-Лівобережний — Бензин А-95
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 15 AND resource_id = 17; -- Склад Тернопіль — Дизельне паливо

-- Electronics category: zero-outs
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 6  AND resource_id = 14; -- Склад Львів — Батарейки AA
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 18 AND resource_id = 14; -- Склад Чернівці — Батарейки AA

-- Clothing category: zero-out
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 20 AND resource_id = 28; -- Склад Кривий Ріг — Спальний мішок

-- Building materials: zero-outs
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 5  AND resource_id = 25; -- Склад Дніпро — Цемент
UPDATE inventories SET quantity = 0 WHERE warehouse_id = 13 AND resource_id = 27; -- Склад Рівне — Цвяхи

-- ============================================================
-- Unusual surpluses on specific (warehouse, resource) pairs
-- ============================================================

-- Склад Київ-Центральний: massive surplus of fuel
UPDATE inventories SET quantity = 8500 WHERE warehouse_id = 1  AND resource_id = 17; -- Дизельне паливо
UPDATE inventories SET quantity = 6200 WHERE warehouse_id = 1  AND resource_id = 18; -- Бензин А-95

-- Склад Одеса-Портовий: large surplus of food (port supply)
UPDATE inventories SET quantity = 12000 WHERE warehouse_id = 4 AND resource_id = 3;  -- Олія соняшникова
UPDATE inventories SET quantity = 9500  WHERE warehouse_id = 4 AND resource_id = 5;  -- Макарони

-- Склад Харків-Головний: surplus of medical supplies
UPDATE inventories SET quantity = 4800 WHERE warehouse_id = 3  AND resource_id = 21; -- Бинт стерильний
UPDATE inventories SET quantity = 3200 WHERE warehouse_id = 3  AND resource_id = 19; -- Маска медична

-- Склад Львів-Захід: surplus of electronics
UPDATE inventories SET quantity = 2100 WHERE warehouse_id = 6  AND resource_id = 15; -- Power Bank (already lowered to 10 by prev migration, override back to surplus)

-- Склад Дніпро-Індустріальний: fuel surplus
UPDATE inventories SET quantity = 5500 WHERE warehouse_id = 5  AND resource_id = 18; -- Бензин А-95

-- Склад Черкаси: building material surplus
UPDATE inventories SET quantity = 3800 WHERE warehouse_id = 10 AND resource_id = 25; -- Цемент
UPDATE inventories SET quantity = 2900 WHERE warehouse_id = 10 AND resource_id = 26; -- Фарба біла

-- Склад Кривий Ріг: clothing surplus
UPDATE inventories SET quantity = 1500 WHERE warehouse_id = 20 AND resource_id = 12; -- Мило туалетне
UPDATE inventories SET quantity = 1200 WHERE warehouse_id = 20 AND resource_id = 11; -- Туалетний папір

-- ============================================================
-- Part 2: Additional demand readings for new (point, resource) pairs
-- ~20 pairs, varied patterns (stable / rising / falling)
-- Points: 1,4,8,10,12,13,16,17,18,19
-- Resources: 3,4,5,6,8,9,10,11,12,13,14,17,18,19,21,24,25,26,27,28
-- ============================================================

-- STABLE (qty=15 all 14 readings)

-- point 1 (АТБ Київ Хрещатик) × resource 3 (Олія соняшникова)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 1, 3, 15,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 4 (Новус Київ Дарниця) × resource 8 (Кава розчинна)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 4, 8, 15,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 8 (Riviera Mall Одеса) × resource 12 (Мило туалетне)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 8, 12, 15,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'manual'
FROM generate_series(1, 14) AS n;

-- point 10 (Дафі Дніпро) × resource 9 (Чай чорний)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 10, 9, 15,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 17 (Сільпо Полтава) × resource 14 (Батарейки AA)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 17, 14, 15,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'manual'
FROM generate_series(1, 14) AS n;

-- point 19 (АТБ Черкаси Митниця) × resource 24 (Папір А4)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 19, 24, 15,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- RISING (qty=12 for n<=8, qty=28 for n>8)

-- point 1 (АТБ Київ Хрещатик) × resource 17 (Дизельне паливо)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 1, 17,
    CASE WHEN n <= 8 THEN 12 ELSE 28 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 4 (Новус Київ Дарниця) × resource 21 (Бинт стерильний)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 4, 21,
    CASE WHEN n <= 8 THEN 12 ELSE 28 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 12 (King Cross Leopolis Львів) × resource 5 (Макарони)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 12, 5,
    CASE WHEN n <= 8 THEN 12 ELSE 28 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 13 (АТБ Запоріжжя Бабурка) × resource 18 (Бензин А-95)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 13, 18,
    CASE WHEN n <= 8 THEN 12 ELSE 28 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 16 (Мегамол Вінниця) × resource 25 (Цемент)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 16, 25,
    CASE WHEN n <= 8 THEN 12 ELSE 28 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'manual'
FROM generate_series(1, 14) AS n;

-- point 18 (Екватор Полтава) × resource 26 (Фарба біла)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 18, 26,
    CASE WHEN n <= 8 THEN 12 ELSE 28 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- FALLING (qty=35 for n<=8, qty=10 for n>8)

-- point 8 (Riviera Mall Одеса) × resource 4 (Цукор)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 8, 4,
    CASE WHEN n <= 8 THEN 35 ELSE 10 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 10 (Дафі Дніпро) × resource 6 (Консерва м'ясна)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 10, 6,
    CASE WHEN n <= 8 THEN 35 ELSE 10 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 12 (King Cross Leopolis Львів) × resource 10 (Пральний порошок)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 12, 10,
    CASE WHEN n <= 8 THEN 35 ELSE 10 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'manual'
FROM generate_series(1, 14) AS n;

-- point 13 (АТБ Запоріжжя Бабурка) × resource 11 (Туалетний папір)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 13, 11,
    CASE WHEN n <= 8 THEN 35 ELSE 10 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 19 (АТБ Черкаси Митниця) × resource 27 (Цвяхи)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 19, 27,
    CASE WHEN n <= 8 THEN 35 ELSE 10 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 18 (Екватор Полтава) × resource 28 (Спальний мішок)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 18, 28,
    CASE WHEN n <= 8 THEN 35 ELSE 10 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- point 16 (Мегамол Вінниця) × resource 13 (Скотч прозорий)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 16, 13,
    CASE WHEN n <= 8 THEN 35 ELSE 10 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'manual'
FROM generate_series(1, 14) AS n;

-- point 17 (Сільпо Полтава) × resource 19 (Маска медична)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 17, 19,
    CASE WHEN n <= 8 THEN 35 ELSE 10 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- ============================================================
-- Part 3: Historical delivery_requests with items and allocations
-- ============================================================

INSERT INTO delivery_requests (destination_id, resource_id, user_id, quantity, priority, status, arrive_till, created_at, updated_at)
VALUES
    (1,  7,  1, 50,  'normal',   'delivered', NOW() - INTERVAL '3 days', NOW() - INTERVAL '4 days', NOW() - INTERVAL '3 days'),
    (5,  22, 3, 10,  'critical', 'in_transit', NOW() + INTERVAL '6 hours', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
    (8,  17, 5, 200, 'elevated', 'allocated',  NOW() + INTERVAL '1 day',  NOW() - INTERVAL '1 day',  NOW() - INTERVAL '1 day'),
    (12, 4,  7, 30,  'urgent',   'pending',    NOW() + INTERVAL '2 hours', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes');

-- delivery_request_items: one item per request, matching the request's resource and quantity
INSERT INTO delivery_request_items (request_id, resource_id, quantity, created_at, updated_at)
SELECT dr.id, dr.resource_id, dr.quantity, dr.created_at, dr.updated_at
FROM delivery_requests dr
WHERE dr.created_at > NOW() - INTERVAL '5 days'
  AND dr.status IN ('pending', 'allocated', 'in_transit', 'delivered');

-- allocations for first 3 requests (delivered, in_transit, allocated) — not the pending one
-- Request 1: delivered — source warehouse 1
INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
SELECT dr.id, 1, dr.resource_id, dr.quantity, 'delivered',
    dr.arrive_till,
    dr.created_at,
    dr.updated_at
FROM delivery_requests dr
WHERE dr.status = 'delivered'
  AND dr.created_at > NOW() - INTERVAL '5 days';

-- Request 2: in_transit — source warehouse 3
INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
SELECT dr.id, 3, dr.resource_id, dr.quantity, 'in_transit',
    NOW() - INTERVAL '1 day',
    dr.created_at,
    dr.updated_at
FROM delivery_requests dr
WHERE dr.status = 'in_transit'
  AND dr.created_at > NOW() - INTERVAL '5 days';

-- Request 3: allocated — source warehouse 5
INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status, dispatched_at, created_at, updated_at)
SELECT dr.id, 5, dr.resource_id, dr.quantity, 'approved',
    NULL,
    dr.created_at,
    dr.updated_at
FROM delivery_requests dr
WHERE dr.status = 'allocated'
  AND dr.created_at > NOW() - INTERVAL '5 days';
