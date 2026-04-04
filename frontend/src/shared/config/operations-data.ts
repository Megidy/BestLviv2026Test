export type StatusTone = 'neutral' | 'success' | 'warning' | 'danger' | 'info';

export type LocationSummary = {
  id: number;
  name: string;
  tone: Exclude<StatusTone, 'info'>;
  resources: number;
  alerts: number;
  lastSync: string;
};

export type InventoryItem = {
  id: string;
  name: string;
  category: string;
  quantity: number;
  unit: string;
  tone: Exclude<StatusTone, 'info'>;
  updated: string;
  location: string;
};

export type AlertItem = {
  id: number;
  location: string;
  resource: string;
  type: 'Actual' | 'Predicted';
  severity: Exclude<StatusTone, 'info'>;
  eta: string;
  owner: string;
  status: 'open' | 'pending' | 'dismissed';
};

export type ResourceActivity = {
  action: string;
  user: string;
  time: string;
};

export const locationSummaries: LocationSummary[] = [
  {
    id: 1,
    name: 'Kyiv DC-7',
    tone: 'success',
    resources: 142,
    alerts: 0,
    lastSync: '14:35',
  },
  {
    id: 2,
    name: 'Lviv Hub-1',
    tone: 'warning',
    resources: 87,
    alerts: 2,
    lastSync: '14:32',
  },
  {
    id: 3,
    name: 'Odesa Port-3',
    tone: 'danger',
    resources: 23,
    alerts: 4,
    lastSync: '14:30',
  },
  {
    id: 4,
    name: 'Dnipro Depot-2',
    tone: 'success',
    resources: 198,
    alerts: 0,
    lastSync: '14:36',
  },
  {
    id: 5,
    name: 'Kharkiv WH-4',
    tone: 'warning',
    resources: 56,
    alerts: 1,
    lastSync: '14:28',
  },
];

export const inventoryItems: InventoryItem[] = [
  {
    id: 'r1',
    name: 'Fuel (Diesel)',
    category: 'Fuel',
    quantity: 340,
    unit: 'L',
    tone: 'success',
    updated: '14:35',
    location: 'Kyiv DC-7',
  },
  {
    id: 'r2',
    name: 'Medical kit',
    category: 'Medical',
    quantity: 28,
    unit: 'units',
    tone: 'success',
    updated: '14:30',
    location: 'Kyiv DC-7',
  },
  {
    id: 'r3',
    name: 'Bottled water',
    category: 'Supply',
    quantity: 14,
    unit: 'pallets',
    tone: 'warning',
    updated: '14:28',
    location: 'Lviv Hub-1',
  },
  {
    id: 'r4',
    name: 'Flour',
    category: 'Food',
    quantity: 620,
    unit: 'kg',
    tone: 'success',
    updated: '14:32',
    location: 'Lviv Hub-1',
  },
  {
    id: 'r5',
    name: 'Generator fuel',
    category: 'Fuel',
    quantity: 45,
    unit: 'L',
    tone: 'danger',
    updated: '14:20',
    location: 'Odesa Port-3',
  },
  {
    id: 'r6',
    name: 'Bandages',
    category: 'Medical',
    quantity: 150,
    unit: 'units',
    tone: 'success',
    updated: '14:25',
    location: 'Kyiv DC-7',
  },
  {
    id: 'r7',
    name: 'Canned food',
    category: 'Food',
    quantity: 8,
    unit: 'pallets',
    tone: 'warning',
    updated: '14:15',
    location: 'Kharkiv WH-4',
  },
  {
    id: 'r8',
    name: 'Blankets',
    category: 'Supply',
    quantity: 200,
    unit: 'units',
    tone: 'success',
    updated: '14:10',
    location: 'Dnipro Depot-2',
  },
];

export const alerts: AlertItem[] = [
  {
    id: 1,
    location: 'Odesa Port-3',
    resource: 'Generator fuel',
    type: 'Actual',
    severity: 'danger',
    eta: 'Now',
    owner: 'Dispatcher Koval',
    status: 'open',
  },
  {
    id: 2,
    location: 'Odesa Port-3',
    resource: 'Bottled water',
    type: 'Actual',
    severity: 'danger',
    eta: 'Now',
    owner: 'Dispatcher Koval',
    status: 'open',
  },
  {
    id: 3,
    location: 'Lviv Hub-1',
    resource: 'Flour',
    type: 'Predicted',
    severity: 'warning',
    eta: '~6h',
    owner: 'Unassigned',
    status: 'pending',
  },
  {
    id: 4,
    location: 'Odesa Port-3',
    resource: 'Medical kit',
    type: 'Actual',
    severity: 'warning',
    eta: 'Now',
    owner: 'Operator Ivanov',
    status: 'open',
  },
  {
    id: 5,
    location: 'Kharkiv WH-4',
    resource: 'Diesel',
    type: 'Predicted',
    severity: 'warning',
    eta: '~12h',
    owner: 'Unassigned',
    status: 'pending',
  },
  {
    id: 6,
    location: 'Lviv Hub-1',
    resource: 'Canned food',
    type: 'Predicted',
    severity: 'success',
    eta: '~24h',
    owner: 'Unassigned',
    status: 'dismissed',
  },
];

export const resourceActivities: Record<string, ResourceActivity[]> = {
  r1: [
    { action: 'Quantity updated', user: 'Operator Ivanov', time: '14:35' },
    { action: 'Automatic recount completed', user: 'System', time: '14:20' },
    {
      action: 'Delivery confirmed',
      user: 'Dispatcher Petrenko',
      time: '12:00',
    },
  ],
  r5: [
    { action: 'Critical threshold crossed', user: 'System', time: '10:15' },
    {
      action: 'Urgent replenishment requested',
      user: 'Dispatcher Koval',
      time: '10:25',
    },
    {
      action: 'Stock manually verified',
      user: 'Operator Ivanov',
      time: '11:05',
    },
  ],
};

export const auditLog = [
  {
    id: 1,
    user: 'Operator Ivanov',
    role: 'operator',
    action: 'update_quantity',
    entity: 'Fuel (Diesel)',
    before: '280 L',
    after: '340 L',
    timestamp: '02.04.2026 14:35',
  },
  {
    id: 2,
    user: 'System',
    role: 'system',
    action: 'auto_rebalance',
    entity: 'Generator fuel',
    before: 'Pending',
    after: 'Transfer T-001 created',
    timestamp: '02.04.2026 10:00',
  },
  {
    id: 3,
    user: 'Dispatcher Petrenko',
    role: 'dispatcher',
    action: 'confirm_delivery',
    entity: 'Medical kit',
    before: 'pending',
    after: 'delivered',
    timestamp: '02.04.2026 12:00',
  },
  {
    id: 4,
    user: 'Dispatcher Koval',
    role: 'dispatcher',
    action: 'create_alert',
    entity: 'Odesa Port-3',
    before: 'No alert',
    after: 'Critical alert',
    timestamp: '02.04.2026 09:45',
  },
  {
    id: 5,
    user: 'Admin',
    role: 'admin',
    action: 'update_threshold',
    entity: 'Bottled water',
    before: '15 pallets',
    after: '20 pallets',
    timestamp: '01.04.2026 18:00',
  },
];
