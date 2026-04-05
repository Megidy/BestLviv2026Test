import {
  type LucideIcon,
  LayoutDashboard,
  Package,
  Map,
  Bell,
  Truck,
  ArrowLeftRight,
  ShieldCheck,
  Settings,
} from 'lucide-react';

export type NavigationItem = {
  to: string;
  label: string;
  description: string;
  icon: LucideIcon;
  /** If set, only users with one of these roles see this item. */
  roles?: string[];
};

export const navigationItems: NavigationItem[] = [
  {
    to: '/dashboard',
    label: 'Dashboard',
    description: 'Operational overview',
    icon: LayoutDashboard,
  },
  {
    to: '/inventory',
    label: 'Inventory',
    description: 'Stock and resources',
    icon: Package,
  },
  {
    to: '/map',
    label: 'Map',
    description: 'Live geospatial view',
    icon: Map,
  },
  {
    to: '/alerts',
    label: 'Alerts',
    description: 'Open incidents',
    icon: Bell,
  },
  {
    to: '/delivery',
    label: 'Delivery',
    description: 'Requests & transfers',
    icon: Truck,
  },
  {
    to: '/allocations',
    label: 'Allocations',
    description: 'Warehouse dispatch',
    icon: ArrowLeftRight,
  },
  {
    to: '/admin',
    label: 'Admin',
    description: 'Audit and controls',
    icon: ShieldCheck,
    roles: ['admin', 'dispatcher'],
  },
];

export const settingsItem: NavigationItem = {
  to: '/settings',
  label: 'Settings',
  description: 'Profile and session',
  icon: Settings,
};
