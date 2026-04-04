import { useLocation } from 'react-router-dom';

const titleByRoute: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/inventory': 'Inventory',
  '/alerts': 'Alerts',
  '/admin': 'Admin',
  '/settings': 'Settings',
};

export function Topbar() {
  const location = useLocation();
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

    </header>
  );
}
