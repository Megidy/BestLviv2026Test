import {
  type LucideIcon,
  LayoutDashboard,
  Package,
  Map,
  Bell,
  ShieldCheck,
  Settings,
} from 'lucide-react';

export type NavigationItem = {
  to: string;
  label: string;
  description: string;
  icon: LucideIcon;
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
    to: '/admin',
    label: 'Admin',
    description: 'Audit and controls',
    icon: ShieldCheck,
  },
];

export const settingsItem: NavigationItem = {
  to: '/settings',
  label: 'Settings',
  description: 'Profile and session',
  icon: Settings,
};
