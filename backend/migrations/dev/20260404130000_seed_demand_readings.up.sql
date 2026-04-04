-- ============================================================
-- Seed demand readings for demo: triggers AI alerts on next
-- prediction run. Inventory is lowered so shortfall math fires.
-- ============================================================

-- ============================================================
-- Step 1: Lower inventory for CRITICAL resources (4 resources)
--   totalStock = 20 * 20 warehouses = 400 units
--   shortfall = (400 / 55) * 6h ≈ 43.6h  < 48h threshold ✓
-- resource 20 = Антисептик 500мл
-- resource 22 = Аптечка тактична
-- resource 23 = Турнікет кровоспинний
-- resource 30 = Генератор 3кВт
-- ============================================================
UPDATE inventories SET quantity = 20 WHERE resource_id IN (20, 22, 23, 30);

-- ============================================================
-- Step 2: Lower inventory for ELEVATED resources (3 resources)
--   totalStock = 10 * 20 warehouses = 200 units
--   shortfall = (200 / 30) * 6h ≈ 40h  < 48h threshold ✓
-- resource 15 = Power Bank 20000mAh
-- resource 16 = Ліхтар LED
-- resource 29 = Рація портативна
-- ============================================================
UPDATE inventories SET quantity = 10 WHERE resource_id IN (15, 16, 29);

-- ============================================================
-- Step 3: Insert demand readings
--
-- Pattern: 14 readings at 6h intervals (oldest → newest).
--   n=1  → recorded_at = NOW() - 78h  (oldest)
--   n=14 → recorded_at = NOW()         (newest)
--
-- CRITICAL  — first 11 readings: qty=20, last 3: qty=55
--   WMA shortAvg=55, longAvg=33.0, divergence=66.7%, confidence=1.0
--
-- ELEVATED  — first 11 readings: qty=20, last 3: qty=30
--   WMA shortAvg=30, longAvg=23.7, divergence=26.5%, confidence=0.66
--
-- NORMAL    — all 14 readings: qty=20 (no alert, shows healthy demand)
-- ============================================================

-- CRITICAL pair 1: Ocean Plaza Kyiv (customer 3) × Аптечка тактична (resource 22)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 3, 22,
    CASE WHEN n <= 11 THEN 20 ELSE 55 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- CRITICAL pair 2: Сільпо Дніпро Перемога (customer 9) × Турнікет кровоспинний (resource 23)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 9, 23,
    CASE WHEN n <= 11 THEN 20 ELSE 55 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- CRITICAL pair 3: City Mall Запоріжжя (customer 14) × Генератор 3кВт (resource 30)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 14, 30,
    CASE WHEN n <= 11 THEN 20 ELSE 55 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- CRITICAL pair 4: Любава Черкаси (customer 20) × Антисептик 500мл (resource 20)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 20, 20,
    CASE WHEN n <= 11 THEN 20 ELSE 55 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- ELEVATED pair 1: Фора Харків Центр (customer 5) × Power Bank 20000mAh (resource 15)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 5, 15,
    CASE WHEN n <= 11 THEN 20 ELSE 30 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- ELEVATED pair 2: Новус Львів Сихів (customer 11) × Ліхтар LED (resource 16)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 11, 16,
    CASE WHEN n <= 11 THEN 20 ELSE 30 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- ELEVATED pair 3: АТБ Одеса Приморський (customer 7) × Рація портативна (resource 29)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 7, 29,
    CASE WHEN n <= 11 THEN 20 ELSE 30 END,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- NORMAL pair 1: Сільпо Київ Оболонь (customer 2) × Вода мінеральна 1.5л (resource 7)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 2, 7, 20,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- NORMAL pair 2: Французький Бульвар Харків (customer 6) × Молоко 2.5% (resource 1)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 6, 1, 20,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;

-- NORMAL pair 3: Фора Вінниця Замостя (customer 15) × Хліб Білий (resource 2)
INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
SELECT 15, 2, 20,
    NOW() - (INTERVAL '1 hour' * (14 - n) * 6),
    'sensor'
FROM generate_series(1, 14) AS n;
