import { useState } from 'react';
import { Outlet } from 'react-router-dom';

import { Sidebar } from '@/widgets/Sidebar';
import { Topbar } from '@/widgets/Topbar';

export function Layout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="grid min-h-screen lg:grid-cols-[220px_minmax(0,1fr)]">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="flex min-h-screen flex-col">
        <Topbar sidebarOpen={sidebarOpen} onMenuToggle={() => setSidebarOpen((prev) => !prev)} />
        <main
          role="main"
          aria-label="Page content"
          className="flex-1 animate-fade-in bg-background px-3 py-4 sm:px-6 sm:py-6"
        >
          <Outlet />
        </main>
      </div>
    </div>
  );
}
