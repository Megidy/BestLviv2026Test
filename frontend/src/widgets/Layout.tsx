import { Outlet } from 'react-router-dom';

import { Sidebar } from '@/widgets/Sidebar';
import { Topbar } from '@/widgets/Topbar';

export function Layout() {
  return (
    <div className="grid min-h-screen lg:grid-cols-[220px_minmax(0,1fr)]">
      <Sidebar />
      <div className="flex min-h-screen flex-col">
        <Topbar />
        <main className="flex-1 animate-fade-in bg-background px-6 py-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
