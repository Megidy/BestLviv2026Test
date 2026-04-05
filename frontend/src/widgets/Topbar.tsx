import { Menu, X } from 'lucide-react';
import { useLocation } from 'react-router-dom';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useNetwork } from '@/shared/hooks/useNetwork';

const titleByRoute: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/inventory': 'Inventory',
  '/alerts': 'Alerts',
  '/admin': 'Admin',
  '/settings': 'Settings',
};

type TopbarProps = {
  sidebarOpen: boolean;
  onMenuToggle: () => void;
};

export function Topbar({ sidebarOpen, onMenuToggle }: TopbarProps) {
  const location = useLocation();
  const { user } = useAuth();
  const { isOnline } = useNetwork();
  const title = location.pathname.startsWith('/resource/')
    ? 'Resource details'
    : (titleByRoute[location.pathname] ?? 'Logisync');

  return (
    <header
      role="banner"
      className="flex h-[73px] min-w-0 items-center justify-between gap-2 border-b border-border bg-surface/40 px-4 backdrop-blur-md sm:gap-4 sm:px-6"
    >
      <div className="flex min-w-0 items-center gap-2 sm:gap-3">
        <button
          type="button"
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-text-muted transition-colors hover:bg-accent hover:text-text focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60 lg:hidden"
          aria-label={sidebarOpen ? 'Close navigation menu' : 'Open navigation menu'}
          aria-expanded={sidebarOpen}
          aria-controls="mobile-sidebar"
          onClick={onMenuToggle}
        >
          {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
        </button>

        <div className="min-w-0">
          <h2 className="truncate text-base font-semibold text-text sm:text-lg">{title}</h2>
          <p className="hidden items-center gap-1.5 text-xs text-text-muted sm:flex">
            <span
              className={`h-1.5 w-1.5 shrink-0 rounded-full ${isOnline ? 'bg-success' : 'bg-warning'}`}
            />
            Europe/Kyiv · {isOnline ? 'Online' : 'Offline'}
          </p>
        </div>
      </div>

      {user ? (
        <div className="shrink-0 text-right">
          <p className="max-w-[120px] truncate text-sm font-medium text-text sm:max-w-none">{user.username}</p>
          <p className="hidden text-xs capitalize text-text-muted sm:block">{user.role}</p>
        </div>
      ) : null}
    </header>
  );
}
