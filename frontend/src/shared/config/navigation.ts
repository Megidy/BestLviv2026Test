export const navigationItems = [
  {
    to: '/dashboard',
    label: 'Dashboard',
    description: 'Operational overview',
  },
  {
    to: '/inventory',
    label: 'Inventory',
    description: 'Stock and resources',
  },
  {
    to: '/map',
    label: 'Map',
    description: 'Live geospatial view',
  },
  {
    to: '/alerts',
    label: 'Alerts',
    description: 'Open incidents',
  },
  {
    to: '/admin',
    label: 'Admin',
    description: 'Audit and controls',
  },
  {
    to: '/settings',
    label: 'Settings',
    description: 'Profile and session',
  },
] as const;
