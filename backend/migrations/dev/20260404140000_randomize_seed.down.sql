-- ============================================================
-- Reverse of 20260404140000_randomize_seed.up.sql
-- ============================================================

-- ============================================================
-- Part 3 rollback: remove delivery_requests, items, allocations
-- added by this migration (within the last 5 days and in known statuses)
-- ============================================================

DELETE FROM allocations
WHERE request_id IN (
    SELECT id FROM delivery_requests
    WHERE created_at > NOW() - INTERVAL '5 days'
      AND status IN ('pending', 'allocated', 'in_transit', 'delivered')
);

DELETE FROM delivery_request_items
WHERE request_id IN (
    SELECT id FROM delivery_requests
    WHERE created_at > NOW() - INTERVAL '5 days'
      AND status IN ('pending', 'allocated', 'in_transit', 'delivered')
);

DELETE FROM delivery_requests
WHERE created_at > NOW() - INTERVAL '5 days'
  AND status IN ('pending', 'allocated', 'in_transit', 'delivered');

-- ============================================================
-- Part 2 rollback: remove new demand readings
-- ============================================================
DELETE FROM demand_readings
WHERE (point_id, resource_id) IN (
    -- STABLE
    (1,  3),  -- АТБ Київ Хрещатик × Олія соняшникова
    (4,  8),  -- Новус Київ Дарниця × Кава розчинна
    (8,  12), -- Riviera Mall Одеса × Мило туалетне
    (10, 9),  -- Дафі Дніпро × Чай чорний
    (17, 14), -- Сільпо Полтава × Батарейки AA
    (19, 24), -- АТБ Черкаси Митниця × Папір А4
    -- RISING
    (1,  17), -- АТБ Київ Хрещатик × Дизельне паливо
    (4,  21), -- Новус Київ Дарниця × Бинт стерильний
    (12, 5),  -- King Cross Leopolis × Макарони
    (13, 18), -- АТБ Запоріжжя × Бензин А-95
    (16, 25), -- Мегамол Вінниця × Цемент
    (18, 26), -- Екватор Полтава × Фарба біла
    -- FALLING
    (8,  4),  -- Riviera Mall Одеса × Цукор
    (10, 6),  -- Дафі Дніпро × Консерва м'ясна
    (12, 10), -- King Cross Leopolis × Пральний порошок
    (13, 11), -- АТБ Запоріжжя × Туалетний папір
    (19, 27), -- АТБ Черкаси Митниця × Цвяхи
    (18, 28), -- Екватор Полтава × Спальний мішок
    (16, 13), -- Мегамол Вінниця × Скотч прозорий
    (17, 19)  -- Сільпо Полтава × Маска медична
);

-- ============================================================
-- Part 1 rollback: restore inventory rows changed by this migration
-- ============================================================

-- Restore zero-out rows (set back to a reasonable default matching
-- the surrounding warehouse baseline of ~100 units)
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 3  AND resource_id = 3;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 7  AND resource_id = 5;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 11 AND resource_id = 6;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 14 AND resource_id = 4;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 19 AND resource_id = 1;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 4  AND resource_id = 19;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 9  AND resource_id = 21;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 17 AND resource_id = 19;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 2  AND resource_id = 18;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 15 AND resource_id = 17;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 6  AND resource_id = 14;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 18 AND resource_id = 14;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 20 AND resource_id = 28;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 5  AND resource_id = 25;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 13 AND resource_id = 27;

-- Restore surplus rows back to baseline
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 1  AND resource_id = 17;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 1  AND resource_id = 18;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 4  AND resource_id = 3;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 4  AND resource_id = 5;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 3  AND resource_id = 21;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 3  AND resource_id = 19;
UPDATE inventories SET quantity = 10  WHERE warehouse_id = 6  AND resource_id = 15; -- restore to the value set by seed_demand_readings migration
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 5  AND resource_id = 18;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 10 AND resource_id = 25;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 10 AND resource_id = 26;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 20 AND resource_id = 12;
UPDATE inventories SET quantity = 100 WHERE warehouse_id = 20 AND resource_id = 11;
