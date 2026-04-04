-- Remove seeded demand readings
DELETE FROM demand_readings
WHERE (point_id, resource_id) IN (
    (3,  22), -- CRITICAL: Ocean Plaza Kyiv × Аптечка тактична
    (9,  23), -- CRITICAL: Сільпо Дніпро × Турнікет кровоспинний
    (14, 30), -- CRITICAL: City Mall Запоріжжя × Генератор 3кВт
    (20, 20), -- CRITICAL: Любава Черкаси × Антисептик 500мл
    (5,  15), -- ELEVATED: Фора Харків × Power Bank
    (11, 16), -- ELEVATED: Новус Львів × Ліхтар LED
    (7,  29), -- ELEVATED: АТБ Одеса × Рація портативна
    (2,   7), -- NORMAL:   Сільпо Київ × Вода мінеральна
    (6,   1), -- NORMAL:   Французький Бульвар × Молоко
    (15,  2)  -- NORMAL:   Фора Вінниця × Хліб Білий
);

-- Restore inventory for lowered resources (approximate original values)
UPDATE inventories SET quantity = CASE warehouse_id
    WHEN 1  THEN 3100 WHEN 2  THEN 2100 WHEN 3  THEN 2600 WHEN 4  THEN 2300
    WHEN 5  THEN 2500 WHEN 6  THEN 2800 WHEN 7  THEN 1500 WHEN 8  THEN 1400
    WHEN 9  THEN 1700 WHEN 10 THEN 1300 WHEN 11 THEN 1400 WHEN 12 THEN 1300
    WHEN 13 THEN 1100 WHEN 14 THEN 1000 WHEN 15 THEN 900  WHEN 16 THEN 850
    WHEN 17 THEN 750  WHEN 18 THEN 700  WHEN 19 THEN 650  WHEN 20 THEN 600
    ELSE quantity END
WHERE resource_id = 20; -- Антисептик 500мл

UPDATE inventories SET quantity = CASE warehouse_id
    WHEN 1  THEN 800  WHEN 2  THEN 550  WHEN 3  THEN 650  WHEN 4  THEN 580
    WHEN 5  THEN 620  WHEN 6  THEN 700  WHEN 7  THEN 400  WHEN 8  THEN 360
    WHEN 9  THEN 420  WHEN 10 THEN 320  WHEN 11 THEN 340  WHEN 12 THEN 310
    WHEN 13 THEN 280  WHEN 14 THEN 260  WHEN 15 THEN 240  WHEN 16 THEN 220
    WHEN 17 THEN 200  WHEN 18 THEN 190  WHEN 19 THEN 180  WHEN 20 THEN 170
    ELSE quantity END
WHERE resource_id = 22; -- Аптечка тактична

UPDATE inventories SET quantity = CASE warehouse_id
    WHEN 1  THEN 550  WHEN 2  THEN 380  WHEN 3  THEN 450  WHEN 4  THEN 400
    WHEN 5  THEN 430  WHEN 6  THEN 480  WHEN 7  THEN 280  WHEN 8  THEN 250
    WHEN 9  THEN 290  WHEN 10 THEN 220  WHEN 11 THEN 235  WHEN 12 THEN 215
    WHEN 13 THEN 195  WHEN 14 THEN 180  WHEN 15 THEN 165  WHEN 16 THEN 155
    WHEN 17 THEN 140  WHEN 18 THEN 130  WHEN 19 THEN 125  WHEN 20 THEN 120
    ELSE quantity END
WHERE resource_id = 23; -- Турнікет кровоспинний

UPDATE inventories SET quantity = CASE warehouse_id
    WHEN 1  THEN 45  WHEN 2  THEN 30  WHEN 3  THEN 35  WHEN 4  THEN 32
    WHEN 5  THEN 34  WHEN 6  THEN 38  WHEN 7  THEN 20  WHEN 8  THEN 18
    WHEN 9  THEN 22  WHEN 10 THEN 16  WHEN 11 THEN 17  WHEN 12 THEN 15
    WHEN 13 THEN 14  WHEN 14 THEN 13  WHEN 15 THEN 12  WHEN 16 THEN 11
    WHEN 17 THEN 10  WHEN 18 THEN 9   WHEN 19 THEN 8   WHEN 20 THEN 7
    ELSE quantity END
WHERE resource_id = 30; -- Генератор 3кВт

UPDATE inventories SET quantity = CASE warehouse_id
    WHEN 1  THEN 600  WHEN 2  THEN 400  WHEN 3  THEN 500  WHEN 4  THEN 450
    WHEN 5  THEN 480  WHEN 6  THEN 550  WHEN 7  THEN 300  WHEN 8  THEN 260
    WHEN 9  THEN 320  WHEN 10 THEN 250  WHEN 11 THEN 265  WHEN 12 THEN 240
    WHEN 13 THEN 220  WHEN 14 THEN 200  WHEN 15 THEN 185  WHEN 16 THEN 175
    WHEN 17 THEN 155  WHEN 18 THEN 145  WHEN 19 THEN 140  WHEN 20 THEN 130
    ELSE quantity END
WHERE resource_id = 15; -- Power Bank 20000mAh

UPDATE inventories SET quantity = CASE warehouse_id
    WHEN 1  THEN 950  WHEN 2  THEN 650  WHEN 3  THEN 800  WHEN 4  THEN 700
    WHEN 5  THEN 750  WHEN 6  THEN 850  WHEN 7  THEN 480  WHEN 8  THEN 420
    WHEN 9  THEN 500  WHEN 10 THEN 390  WHEN 11 THEN 410  WHEN 12 THEN 380
    WHEN 13 THEN 350  WHEN 14 THEN 320  WHEN 15 THEN 295  WHEN 16 THEN 275
    WHEN 17 THEN 250  WHEN 18 THEN 235  WHEN 19 THEN 220  WHEN 20 THEN 210
    ELSE quantity END
WHERE resource_id = 16; -- Ліхтар LED

UPDATE inventories SET quantity = CASE warehouse_id
    WHEN 1  THEN 150  WHEN 2  THEN 100  WHEN 3  THEN 120  WHEN 4  THEN 110
    WHEN 5  THEN 115  WHEN 6  THEN 130  WHEN 7  THEN 70   WHEN 8  THEN 65
    WHEN 9  THEN 75   WHEN 10 THEN 60   WHEN 11 THEN 62   WHEN 12 THEN 57
    WHEN 13 THEN 52   WHEN 14 THEN 48   WHEN 15 THEN 44   WHEN 16 THEN 41
    WHEN 17 THEN 37   WHEN 18 THEN 35   WHEN 19 THEN 33   WHEN 20 THEN 31
    ELSE quantity END
WHERE resource_id = 29; -- Рація портативна
