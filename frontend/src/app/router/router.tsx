import { Navigate, createBrowserRouter } from 'react-router-dom';

import { AlertsPage } from '@/pages/Alerts';
import { AdminPage } from '@/pages/Admin';
import { DashboardPage } from '@/pages/Dashboard';
import { InventoryPage } from '@/pages/Inventory';
import { LoginPage } from '@/pages/Login';
import { MapPage } from '@/pages/Map';
import { ResourcePage } from '@/pages/Resource';
import { SettingsPage } from '@/pages/Settings';
import { Layout } from '@/widgets/Layout';

export const router = createBrowserRouter([
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    path: '/',
    element: <Layout />,
    children: [
      {
        index: true,
        element: <Navigate replace to="/dashboard" />,
      },
      {
        path: 'dashboard',
        element: <DashboardPage />,
      },
      {
        path: 'inventory',
        element: <InventoryPage />,
      },
      {
        path: 'resource/:id',
        element: <ResourcePage />,
      },
      {
        path: 'map',
        element: <MapPage />,
      },
      {
        path: 'alerts',
        element: <AlertsPage />,
      },
      {
        path: 'admin',
        element: <AdminPage />,
      },
      {
        path: 'settings',
        element: <SettingsPage />,
      },
    ],
  },
  {
    path: '*',
    element: <Navigate replace to="/dashboard" />,
  },
]);
