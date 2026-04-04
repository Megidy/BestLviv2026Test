import { useLocation } from 'react-router-dom';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { Badge } from '@/shared/ui/Badge';

const titleByRoute: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/inventory': 'Inventory',
  '/alerts': 'Alerts',
  '/admin': 'Admin',
  '/settings': 'Settings',
};

export function Topbar() {
  const location = useLocation();
  const { user } = useAuth();
  const title = location.pathname.startsWith('/resource/')
    ? 'Resource details'
    : (titleByRoute[location.pathname] ?? 'Logisync');

  return (
    <header className="flex h-[73px] items-center justify-between gap-4 border-b border-border bg-surface/40 px-6 backdrop-blur-md">
      <div>
        <h2 className="text-lg font-semibold text-text">{title}</h2>
        <p className="flex items-center gap-1.5 text-xs text-text-muted">
          <span className="h-1.5 w-1.5 rounded-full bg-success" />
          Europe/Kyiv · Online
        </p>
      </div>

      <div className="flex items-center gap-3">
        {user ? (
          <>
            <div className="text-right">
              <p className="text-sm font-medium text-text">{user.username}</p>
              <p className="text-xs capitalize text-text-muted">{user.role}</p>
            </div>
            <Badge tone="info">Location #{user.location_id}</Badge>
          </>
        ) : null}
      </div>
    </header>
  );
}
