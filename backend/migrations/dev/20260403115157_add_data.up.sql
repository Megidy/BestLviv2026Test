INSERT INTO warehouses (id, name, latitude, longitude) VALUES
  (1,  'Склад Київ-Центральний',           50.4501, 30.5234),
  (2,  'Склад Київ-Лівобережний',          50.4710, 30.6350),
  (3,  'Склад Харків-Головний',            49.9935, 36.2304),
  (4,  'Склад Одеса-Портовий',             46.4825, 30.7233),
  (5,  'Склад Дніпро-Індустріальний',      48.4647, 35.0462),
  (6,  'Склад Львів-Захід',                49.8397, 24.0297),
  (7,  'Склад Запоріжжя',                  47.8388, 35.1396),
  (8,  'Склад Вінниця',                    49.2331, 28.4682),
  (9,  'Склад Полтава',                    49.5883, 34.5514),
  (10, 'Склад Черкаси',                    49.4444, 32.0598),
  (11, 'Склад Миколаїв-Південь',           46.9750, 31.9946),
  (12, 'Склад Житомир',                    50.2547, 28.6587),
  (13, 'Склад Рівне',                      50.6199, 26.2516),
  (14, 'Склад Луцьк',                      50.7472, 25.3254),
  (15, 'Склад Тернопіль',                  49.5535, 25.5948),
  (16, 'Склад Івано-Франківськ',           48.9226, 24.7111),
  (17, 'Склад Ужгород',                    48.6208, 22.2879),
  (18, 'Склад Чернівці',                   48.2921, 25.9353),
  (19, 'Склад Хмельницький',               49.4230, 26.9870),
  (20, 'Склад Кривий Ріг',                 47.9100, 33.3900);

INSERT INTO customers (id, name, type, latitude, longitude) VALUES
  (1,  'АТБ Київ Хрещатик',          'shop', 50.4480, 30.5150),
  (2,  'Сільпо Київ Оболонь',        'shop', 50.5012, 30.4978),
  (3,  'Ocean Plaza Київ',           'mall', 50.4167, 30.5167),
  (4,  'Новус Київ Дарниця',         'shop', 50.4350, 30.6450),
  (5,  'Фора Харків Центр',          'shop', 49.9915, 36.2410),
  (6,  'Французький Бульвар Харків', 'mall', 49.9850, 36.2750),
  (7,  'АТБ Одеса Приморський',      'shop', 46.4780, 30.7410),
  (8,  'Riviera Mall Одеса',         'mall', 46.4333, 30.7333),
  (9,  'Сільпо Дніпро Перемога',     'shop', 48.4590, 35.0520),
  (10, 'Дафі Дніпро',                'mall', 48.4333, 35.0500),
  (11, 'Новус Львів Сихів',          'shop', 49.8010, 24.0500),
  (12, 'King Cross Leopolis Львів',  'mall', 49.8500, 23.9667),
  (13, 'АТБ Запоріжжя Бабурка',      'shop', 47.8400, 35.1000),
  (14, 'City Mall Запоріжжя',        'mall', 47.8167, 35.1667),
  (15, 'Фора Вінниця Замостя',       'shop', 49.2280, 28.4750),
  (16, 'Мегамол Вінниця',            'mall', 49.2333, 28.4667),
  (17, 'Сільпо Полтава',             'shop', 49.5790, 34.5620),
  (18, 'Екватор Полтава',            'mall', 49.5833, 34.5500),
  (19, 'АТБ Черкаси Митниця',        'shop', 49.4320, 32.0710),
  (20, 'Любава Черкаси',             'mall', 49.4500, 32.0500),
  (21, 'Сільпо Миколаїв Центр',      'shop', 46.9750, 31.9946),
  (22, 'City Center Миколаїв',       'mall', 46.9800, 31.9950),
  (23, 'АТБ Житомир',                'shop', 50.2547, 28.6600),
  (24, 'Глобал UA Житомир',          'mall', 50.2600, 28.6650),
  (25, 'Фора Рівне',                 'shop', 50.6199, 26.2600),
  (26, 'Злата Плаза Рівне',          'mall', 50.6250, 26.2500),
  (27, 'Сільпо Луцьк',               'shop', 50.7472, 25.3300),
  (28, 'ПортCity Луцьк',             'mall', 50.7550, 25.3400),
  (29, 'АТБ Тернопіль Аляска',       'shop', 49.5535, 25.6000),
  (30, 'Подоляни Тернопіль',         'mall', 49.5450, 25.5850),
  (31, 'Сільпо Івано-Франківськ',    'shop', 48.9226, 24.7200),
  (32, 'Veles Mall Франківськ',      'mall', 48.9250, 24.7250),
  (33, 'АТБ Ужгород',                'shop', 48.6208, 22.2950),
  (34, 'Tokyo Ужгород',              'mall', 48.6350, 22.3050),
  (35, 'Фора Чернівці',              'shop', 48.2921, 25.9400),
  (36, 'Depo''t Чернівці',           'mall', 48.3050, 25.9500),
  (37, 'Сільпо Хмельницький',        'shop', 49.4230, 26.9900),
  (38, 'Оазис Хмельницький',         'mall', 49.4350, 26.9950),
  (39, 'АТБ Кривий Ріг',             'shop', 47.9100, 33.3600),
  (40, 'Сонячна Галерея Кривий Ріг', 'mall', 47.9500, 33.3900);


INSERT INTO resources (id, name, category, unit_measure, logo_uri) VALUES
  (1,  'Молоко 2.5%',           'food',        'л',    'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=300&q=80'),
  (2,  'Хліб Білий',            'food',        'шт',   'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=300&q=80'),
  (3,  'Олія соняшникова 1л',   'food',        'шт',   'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=300&q=80'),
  (4,  'Цукор 1кг',             'food',        'кг',   'https://images.unsplash.com/photo-1581441363689-1f3c3c414635?auto=format&fit=crop&w=300&q=80'),
  (5,  'Макарони 500г',         'food',        'шт',   'https://images.unsplash.com/photo-1551462147-37885acc36f1?auto=format&fit=crop&w=300&q=80'),
  (6,  'Консерва м''ясна',       'food',        'шт',   'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&w=300&q=80'),
  (7,  'Вода мінеральна 1.5л',  'beverages',   'шт',   'https://images.unsplash.com/photo-1523362628745-0c100150b504?auto=format&fit=crop&w=300&q=80'),
  (8,  'Кава розчинна 200г',    'beverages',   'шт',   'https://images.unsplash.com/photo-1559525839-b184a4d698c7?auto=format&fit=crop&w=300&q=80'),
  (9,  'Чай чорний 25 пак',     'beverages',   'упак', 'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?auto=format&fit=crop&w=300&q=80'),
  (10, 'Пральний порошок 3кг',  'household',   'шт',   'https://images.unsplash.com/photo-1584820927498-cafe4c23ba0f?auto=format&fit=crop&w=300&q=80'),
  (11, 'Туалетний папір 4рул',  'household',   'упак', 'https://images.unsplash.com/photo-1584556812952-905ffd0c611a?auto=format&fit=crop&w=300&q=80'),
  (12, 'Мило туалетне 100г',    'household',   'шт',   'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec?auto=format&fit=crop&w=300&q=80'),
  (13, 'Скотч прозорий',        'household',   'шт',   'https://images.unsplash.com/photo-1601055903647-8f967cc99432?auto=format&fit=crop&w=300&q=80'),
  (14, 'Батарейки AA 4шт',      'electronics', 'упак', 'https://images.unsplash.com/photo-1584347596001-c8524e930cb9?auto=format&fit=crop&w=300&q=80'),
  (15, 'Power Bank 20000mAh',   'electronics', 'шт',   'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?auto=format&fit=crop&w=300&q=80'),
  (16, 'Ліхтар LED',            'electronics', 'шт',   'https://images.unsplash.com/photo-1559828478-f7b2aa84333b?auto=format&fit=crop&w=300&q=80'),
  (17, 'Дизельне паливо',       'fuel',        'л',    'https://images.unsplash.com/photo-1527018601619-a508a2be00cd?auto=format&fit=crop&w=300&q=80'),
  (18, 'Бензин А-95',           'fuel',        'л',    'https://images.unsplash.com/photo-1621213032486-5743b177d614?auto=format&fit=crop&w=300&q=80'),
  (19, 'Маска медична 50шт',    'medical',     'упак', 'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?auto=format&fit=crop&w=300&q=80'),
  (20, 'Антисептик 500мл',      'medical',     'шт',   'https://images.unsplash.com/photo-1584744982491-665216d95f8b?auto=format&fit=crop&w=300&q=80'),
  (21, 'Бинт стерильний 5м',    'medical',     'шт',   'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=300&q=80'),
  (22, 'Аптечка тактична',      'medical',     'шт',   'https://images.unsplash.com/photo-1603398938378-e54eab446dde?auto=format&fit=crop&w=300&q=80'),
  (23, 'Турнікет кровоспинний', 'medical',     'шт',   'https://images.unsplash.com/photo-1583324113626-70df0f4deaab?auto=format&fit=crop&w=300&q=80'),
  (24, 'Папір А4 500арк',       'stationery',  'упак', 'https://images.unsplash.com/photo-1586075010923-2dd4570fb338?auto=format&fit=crop&w=300&q=80'),
  (25, 'Цемент 25кг',           'building',    'мішок','https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&w=300&q=80'),
  (26, 'Фарба біла 10л',        'building',    'відро','https://images.unsplash.com/photo-1562259949-e8e7689d7828?auto=format&fit=crop&w=300&q=80'),
  (27, 'Цвяхи 1кг',             'building',    'кг',   'https://images.unsplash.com/photo-1532054041703-cb6cb9a896a2?auto=format&fit=crop&w=300&q=80'),
  (28, 'Спальний мішок',        'clothing',    'шт',   'https://images.unsplash.com/photo-1552596489-0824b22db84a?auto=format&fit=crop&w=300&q=80'),
  (29, 'Рація портативна',      'communications','шт', 'https://images.unsplash.com/photo-1586208552178-5777ce71b87a?auto=format&fit=crop&w=300&q=80'),
  (30, 'Генератор 3кВт',        'electronics', 'шт',   'https://images.unsplash.com/photo-1614088812613-58daeaabec7e?auto=format&fit=crop&w=300&q=80');


INSERT INTO users (username, password_hash, role, warehouse_id) VALUES
  ('admin_w1',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',      1),
  ('dispatcher_w1', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher', 1),
  ('worker1_w1',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     1),
  ('worker2_w1',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     1),
  ('worker3_w1',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     1),
  ('worker4_w1',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     1),
  
  ('admin_w2',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',      2),
  ('dispatcher_w2', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher', 2),
  ('worker1_w2',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     2),
  ('worker2_w2',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     2),
  ('worker3_w2',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     2),

  ('admin_w3',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',      3),
  ('dispatcher_w3', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher', 3),
  ('worker1_w3',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     3),
  ('worker2_w3',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     3),
  ('worker3_w3',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     3),
  ('worker4_w3',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     3),

  ('admin_w4',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',      4),
  ('dispatcher_w4', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher', 4),
  ('worker1_w4',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     4),
  ('worker2_w4',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     4),
  ('worker3_w4',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     4),

  ('admin_w5',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',      5),
  ('dispatcher_w5', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher', 5),
  ('worker1_w5',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     5),
  ('worker2_w5',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     5),
  ('worker3_w5',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     5),

  ('admin_w6',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',      6),
  ('dispatcher_w6', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher', 6),
  ('worker1_w6',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     6),
  ('worker2_w6',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     6),
  ('worker3_w6',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     6),
  ('worker4_w6',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     6),

  ('admin_w7',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',      7),
  ('dispatcher_w7', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher', 7),
  ('worker1_w7',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     7),
  ('worker2_w7',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     7),

  ('admin_w8',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',      8),
  ('dispatcher_w8', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher', 8),
  ('worker1_w8',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     8),
  ('worker2_w8',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     8),
  ('worker3_w8',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     8),

  ('admin_w9',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',      9),
  ('dispatcher_w9', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher', 9),
  ('worker1_w9',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     9),
  ('worker2_w9',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',     9),

  ('admin_w10',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     10),
  ('dispatcher_w10', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',10),
  ('worker1_w10',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    10),
  ('worker2_w10',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    10),
  ('worker3_w10',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    10),

  ('admin_w11',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     11),
  ('dispatcher_w11', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',11),
  ('worker1_w11',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    11),
  ('worker2_w11',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    11),

  ('admin_w12',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     12),
  ('dispatcher_w12', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',12),
  ('worker1_w12',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    12),
  ('worker2_w12',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    12),

  ('admin_w13',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     13),
  ('dispatcher_w13', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',13),
  ('worker1_w13',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    13),
  ('worker2_w13',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    13),
  ('worker3_w13',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    13),

  ('admin_w14',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     14),
  ('dispatcher_w14', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',14),
  ('worker1_w14',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    14),
  ('worker2_w14',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    14),

  ('admin_w15',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     15),
  ('dispatcher_w15', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',15),
  ('worker1_w15',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    15),
  ('worker2_w15',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    15),

  ('admin_w16',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     16),
  ('dispatcher_w16', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',16),
  ('worker1_w16',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    16),
  ('worker2_w16',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    16),
  ('worker3_w16',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    16),

  ('admin_w17',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     17),
  ('dispatcher_w17', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',17),
  ('worker1_w17',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    17),
  ('worker2_w17',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    17),

  ('admin_w18',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     18),
  ('dispatcher_w18', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',18),
  ('worker1_w18',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    18),
  ('worker2_w18',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    18),
  ('worker3_w18',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    18),

  ('admin_w19',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     19),
  ('dispatcher_w19', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',19),
  ('worker1_w19',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    19),
  ('worker2_w19',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    19),

  ('admin_w20',      '$2a$12$mDCfeTQRspL0kT6Z4EC5iOJsKDTahUGrQUhHFmGHwEaEeLOD2ARh6', 'admin',     20),
  ('dispatcher_w20', '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'dispatcher',20),
  ('worker1_w20',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    20),
  ('worker2_w20',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    20),
  ('worker3_w20',    '$2a$12$fNQtBa3OT09yJBv07jZYe.Wilq5ibKetQ1yDa6iBm3LzXhveXuzU6', 'worker',    20);


INSERT INTO inventories (warehouse_id, resource_id, quantity) VALUES
-- W1: Київ-Центральний (Huge hub)
(1,1,8500),  (1,2,6200),  (1,3,4100),  (1,4,5000),  (1,5,3800),
(1,6,2700),  (1,7,12000), (1,8,1800),  (1,9,2100),  (1,10,1500),
(1,11,4000), (1,12,3200), (1,13,850),  (1,14,1400), (1,15,600),
(1,16,950),  (1,17,25000),(1,18,18000),(1,19,6500), (1,20,3100),
(1,21,4200), (1,22,800),  (1,23,550),  (1,24,1200), (1,25,180),
(1,26,450),  (1,27,650),  (1,28,320),  (1,29,150),  (1,30,45),

-- W2: Київ-Лівобережний
(2,1,5400),  (2,2,4100),  (2,3,2800),  (2,4,3500),  (2,5,2500),
(2,6,1900),  (2,7,8500),  (2,8,1200),  (2,9,1500),  (2,10,950),
(2,11,2800), (2,12,2100), (2,13,600),  (2,14,900),  (2,15,400),
(2,16,650),  (2,17,18000),(2,18,12000),(2,19,4200), (2,20,2100),
(2,21,2800), (2,22,550),  (2,23,380),  (2,24,850),  (2,25,120),
(2,26,300),  (2,27,450),  (2,28,210),  (2,29,100),  (2,30,30),

-- W3: Харків-Головний
(3,1,7200),  (3,2,5500),  (3,3,3400),  (3,4,4200),  (3,5,3100),
(3,6,2200),  (3,7,9800),  (3,8,1500),  (3,9,1800),  (3,10,1200),
(3,11,3500), (3,12,2700), (3,13,750),  (3,14,1100), (3,15,500),
(3,16,800),  (3,17,21000),(3,18,15000),(3,19,5400), (3,20,2600),
(3,21,3500), (3,22,650),  (3,23,450),  (3,24,1000), (3,25,150),
(3,26,380),  (3,27,550),  (3,28,260),  (3,29,120),  (3,30,35),

-- W4: Одеса-Портовий
(4,1,6100),  (4,2,4800),  (4,3,2900),  (4,4,3700),  (4,5,2700),
(4,6,1900),  (4,7,8600),  (4,8,1300),  (4,9,1600),  (4,10,1050),
(4,11,3100), (4,12,2300), (4,13,650),  (4,14,950),  (4,15,450),
(4,16,700),  (4,17,19000),(4,18,13500),(4,19,4800), (4,20,2300),
(4,21,3100), (4,22,580),  (4,23,400),  (4,24,900),  (4,25,135),
(4,26,340),  (4,27,480),  (4,28,230),  (4,29,110),  (4,30,32),

-- W5: Дніпро-Індустріальний
(5,1,6800),  (5,2,5200),  (5,3,3200),  (5,4,4000),  (5,5,3000),
(5,6,2100),  (5,7,9200),  (5,8,1400),  (5,9,1700),  (5,10,1150),
(5,11,3300), (5,12,2500), (5,13,700),  (5,14,1050), (5,15,480),
(5,16,750),  (5,17,20000),(5,18,14000),(5,19,5100), (5,20,2500),
(5,21,3300), (5,22,620),  (5,23,430),  (5,24,950),  (5,25,145),
(5,26,360),  (5,27,520),  (5,28,250),  (5,29,115),  (5,30,34),

-- W6: Львів-Захід
(6,1,7500),  (6,2,5800),  (6,3,3600),  (6,4,4500),  (6,5,3300),
(6,6,2400),  (6,7,10500), (6,8,1600),  (6,9,1900),  (6,10,1300),
(6,11,3700), (6,12,2800), (6,13,780),  (6,14,1200), (6,15,550),
(6,16,850),  (6,17,22000),(6,18,16000),(6,19,5800), (6,20,2800),
(6,21,3700), (6,22,700),  (6,23,480),  (6,24,1050), (6,25,160),
(6,26,410),  (6,27,580),  (6,28,280),  (6,29,130),  (6,30,38),

-- W7: Запоріжжя
(7,1,4200),  (7,2,3100),  (7,3,1900),  (7,4,2400),  (7,5,1800),
(7,6,1300),  (7,7,5800),  (7,8,850),   (7,9,1100),  (7,10,750),
(7,11,2100), (7,12,1500), (7,13,450),  (7,14,650),  (7,15,300),
(7,16,480),  (7,17,12000),(7,18,8500), (7,19,3200), (7,20,1500),
(7,21,2100), (7,22,400),  (7,23,280),  (7,24,600),  (7,25,90),
(7,26,230),  (7,27,320),  (7,28,150),  (7,29,70),   (7,30,20),

-- W8: Вінниця
(8,1,3800),  (8,2,2800),  (8,3,1700),  (8,4,2200),  (8,5,1600),
(8,6,1200),  (8,7,5200),  (8,8,750),   (8,9,950),   (8,10,650),
(8,11,1900), (8,12,1400), (8,13,400),  (8,14,580),  (8,15,260),
(8,16,420),  (8,17,11000),(8,18,7800), (8,19,2900), (8,20,1400),
(8,21,1900), (8,22,360),  (8,23,250),  (8,24,550),  (8,25,80),
(8,26,210),  (8,27,290),  (8,28,140),  (8,29,65),   (8,30,18),

-- W9: Полтава
(9,1,4500),  (9,2,3400),  (9,3,2100),  (9,4,2600),  (9,5,1900),
(9,6,1400),  (9,7,6200),  (9,8,950),   (9,9,1200),  (9,10,800),
(9,11,2300), (9,12,1700), (9,13,480),  (9,14,700),  (9,15,320),
(9,16,500),  (9,17,13000),(9,18,9200), (9,19,3500), (9,20,1700),
(9,21,2300), (9,22,420),  (9,23,290),  (9,24,650),  (9,25,95),
(9,26,250),  (9,27,350),  (9,28,160),  (9,29,75),   (9,30,22),

-- W10: Черкаси
(10,1,3500), (10,2,2600), (10,3,1600), (10,4,2000), (10,5,1500),
(10,6,1100), (10,7,4800), (10,8,700),  (10,9,900),  (10,10,600),
(10,11,1700),(10,12,1300),(10,13,380), (10,14,550), (10,15,250),
(10,16,390), (10,17,10000),(10,18,7000),(10,19,2700),(10,20,1300),
(10,21,1700),(10,22,320), (10,23,220), (10,24,500), (10,25,75),
(10,26,190), (10,27,270), (10,28,125), (10,29,60),  (10,30,16),

-- W11 to W20 will have progressively slightly smaller but realistic values
-- W11: Миколаїв
(11,1,3900), (11,2,2900), (11,3,1800), (11,4,2300), (11,5,1700),
(11,6,1200), (11,7,5300), (11,8,780),  (11,9,980),  (11,10,670),
(11,11,1900),(11,12,1450),(11,13,410), (11,14,600), (11,15,270),
(11,16,430), (11,17,11200),(11,18,7900),(11,19,3000),(11,20,1450),
(11,21,1900),(11,22,370), (11,23,250), (11,24,560), (11,25,82),
(11,26,215), (11,27,300), (11,28,140), (11,29,65),  (11,30,19),

-- W12: Житомир
(12,1,3200), (12,2,2400), (12,3,1500), (12,4,1900), (12,5,1400),
(12,6,1000), (12,7,4400), (12,8,640),  (12,9,800),  (12,10,550),
(12,11,1600),(12,12,1200),(12,13,340), (12,14,490), (12,15,220),
(12,16,350), (12,17,9100), (12,18,6500),(12,19,2400),(12,20,1200),
(12,21,1600),(12,22,300), (12,23,210), (12,24,460), (12,25,68),
(12,26,170), (12,27,240), (12,28,110), (12,29,55),  (12,30,15),

-- W13: Рівне
(13,1,3400), (13,2,2500), (13,3,1600), (13,4,2000), (13,5,1500),
(13,6,1100), (13,7,4700), (13,8,680),  (13,9,850),  (13,10,580),
(13,11,1700),(13,12,1300),(13,13,360), (13,14,520), (13,15,230),
(13,16,370), (13,17,9700), (13,18,6900),(13,19,2600),(13,20,1300),
(13,21,1700),(13,22,320), (13,23,220), (13,24,490), (13,25,72),
(13,26,185), (13,27,260), (13,28,120), (13,29,60),  (13,30,16),

-- W14: Луцьк
(14,1,3100), (14,2,2300), (14,3,1400), (14,4,1800), (14,5,1300),
(14,6,950),  (14,7,4200), (14,8,620),  (14,9,780),  (14,10,530),
(14,11,1550),(14,12,1150),(14,13,330), (14,14,470), (14,15,210),
(14,16,340), (14,17,8800), (14,18,6200),(14,19,2300),(14,20,1150),
(14,21,1500),(14,22,290), (14,23,200), (14,24,440), (14,25,65),
(14,26,165), (14,27,230), (14,28,110), (14,29,52),  (14,30,14),

-- W15: Тернопіль
(15,1,2900), (15,2,2100), (15,3,1300), (15,4,1700), (15,5,1200),
(15,6,900),  (15,7,4000), (15,8,580),  (15,9,720),  (15,10,490),
(15,11,1450),(15,12,1100),(15,13,310), (15,14,440), (15,15,200),
(15,16,320), (15,17,8200), (15,18,5800),(15,19,2200),(15,20,1080),
(15,21,1400),(15,22,270), (15,23,190), (15,24,410), (15,25,60),
(15,26,150), (15,27,215), (15,28,100), (15,29,48),  (15,30,13),

-- W16: Івано-Франківськ
(16,1,3300), (16,2,2400), (16,3,1500), (16,4,1900), (16,5,1400),
(16,6,1050), (16,7,4500), (16,8,660),  (16,9,820),  (16,10,560),
(16,11,1650),(16,12,1250),(16,13,350), (16,14,500), (16,15,220),
(16,16,360), (16,17,9400), (16,18,6700),(16,19,2500),(16,20,1250),
(16,21,1600),(16,22,310), (16,23,210), (16,24,470), (16,25,70),
(16,26,180), (16,27,250), (16,28,115), (16,29,58),  (16,30,15),

-- W17: Ужгород
(17,1,2800), (17,2,2000), (17,3,1200), (17,4,1600), (17,5,1150),
(17,6,850),  (17,7,3800), (17,8,560),  (17,9,700),  (17,10,470),
(17,11,1400),(17,12,1050),(17,13,300), (17,14,420), (17,15,190),
(17,16,300), (17,17,7900), (17,18,5600),(17,19,2100),(17,20,1050),
(17,21,1350),(17,22,260), (17,23,180), (17,24,400), (17,25,58),
(17,26,145), (17,27,200), (17,28,95),  (17,29,45),  (17,30,12),

-- W18: Чернівці
(18,1,3000), (18,2,2200), (18,3,1350), (18,4,1750), (18,5,1250),
(18,6,920),  (18,7,4100), (18,8,600),  (18,9,750),  (18,10,510),
(18,11,1500),(18,12,1120),(18,13,320), (18,14,450), (18,15,200),
(18,16,320), (18,17,8500), (18,18,6000),(18,19,2250),(18,20,1100),
(18,21,1450),(18,22,280), (18,23,195), (18,24,420), (18,25,62),
(18,26,155), (18,27,220), (18,28,105), (18,29,50),  (18,30,14),

-- W19: Хмельницький
(19,1,3600), (19,2,2600), (19,3,1650), (19,4,2100), (19,5,1500),
(19,6,1100), (19,7,4900), (19,8,720),  (19,9,900),  (19,10,610),
(19,11,1800),(19,12,1350),(19,13,380), (19,14,540), (19,15,240),
(19,16,390), (19,17,10200),(19,18,7200),(19,19,2750),(19,20,1350),
(19,21,1750),(19,22,340), (19,23,235), (19,24,510), (19,25,76),
(19,26,195), (19,27,270), (19,28,125), (19,29,62),  (19,30,17),

-- W20: Кривий Ріг
(20,1,4100), (20,2,3000), (20,3,1850), (20,4,2350), (20,5,1750),
(20,6,1250), (20,7,5600), (20,8,820),  (20,9,1050), (20,10,710),
(20,11,2000),(20,12,1480),(20,13,430), (20,14,620), (20,15,280),
(20,16,450), (20,17,11800),(20,18,8200),(20,19,3100),(20,20,1550),
(20,21,2000),(20,22,380), (20,23,265), (20,24,580), (20,25,86),
(20,26,220), (20,27,310), (20,28,145), (20,29,68),  (20,30,19);