import { NavLink } from 'react-router-dom';

import { navigationItems } from '@/shared/config/navigation';
import { cn } from '@/shared/lib/cn';

export function Sidebar() {
  return (
    <aside className="flex h-full flex-col border-r border-border bg-surface/80 backdrop-blur-md">
      <div className="border-b border-border px-5 py-5">
        <div className="flex items-center gap-2.5">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/20 shadow-glow">
            <span className="text-sm font-bold text-primary">L</span>
          </div>
          <div>
            <p className="text-sm font-semibold tracking-wide text-text">
              Logisync
            </p>
            <p className="text-[10px] uppercase tracking-[0.2em] text-text-muted">
              Operations hub
            </p>
          </div>
        </div>
      </div>

      <nav className="flex-1 space-y-1 px-3 py-4">
        {navigationItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              cn(
                'group block rounded-xl px-3 py-3 transition-all duration-200',
                isActive
                  ? 'bg-primary/15 text-text shadow-glow'
                  : 'text-text-muted hover:bg-accent hover:text-text',
              )
            }
          >
            {({ isActive }) => (
              <>
                <span
                  className={cn(
                    'block text-sm font-medium',
                    isActive && 'text-primary',
                  )}
                >
                  {item.label}
                </span>
                <span className="mt-0.5 block text-xs opacity-60">
                  {item.description}
                </span>
              </>
            )}
          </NavLink>
        ))}
      </nav>

      <div className="border-t border-border px-5 py-4">
        <div className="flex items-center gap-2">
          <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-success shadow-[0_0_6px_rgba(78,122,81,0.5)]" />
          <span className="text-xs text-text-muted">v0.1.0 · online</span>
        </div>
      </div>
    </aside>
  );
}
