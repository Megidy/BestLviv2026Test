import { useEffect, useRef } from 'react';
import { NavLink } from 'react-router-dom';
import { X } from 'lucide-react';

import { navigationItems, settingsItem } from '@/shared/config/navigation';
import { useAuth } from '@/features/auth/hooks/useAuth';
import { cn } from '@/shared/lib/cn';
import { useNetwork } from '@/shared/hooks/useNetwork';

type SidebarProps = {
  open: boolean;
  onClose: () => void;
};

function SidebarContent({ onClose }: { onClose?: () => void }) {
  const { isOnline } = useNetwork();
  const { user } = useAuth();
  const visibleItems = navigationItems.filter(
    (item) => !item.roles || (user?.role && item.roles.includes(user.role)),
  );
  return (
    <>
      <div className="flex h-[73px] items-center justify-between border-b border-border px-5">
        <div className="flex items-center gap-2.5">
          <div className="flex h-8 w-8 items-center justify-center">
            <img src="/logo.png" alt="Logisync" className="h-8 w-8 object-contain" />
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
        {onClose ? (
          <button
            type="button"
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-lg text-text-muted transition-colors hover:bg-accent hover:text-text focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60 lg:hidden"
            aria-label="Close menu"
          >
            <X size={18} />
          </button>
        ) : null}
      </div>

      <nav
        aria-label="Main navigation"
        className="flex-1 space-y-1 px-3 py-4"
      >
        {visibleItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            onClick={onClose}
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
              <div className="flex items-center gap-3">
                <item.icon
                  size={17}
                  className={cn(
                    'shrink-0 transition-colors duration-200',
                    isActive ? 'text-primary' : 'text-text-muted group-hover:text-text',
                  )}
                />
                <div>
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
                </div>
              </div>
            )}
          </NavLink>
        ))}
      </nav>

      <div className="px-3 pb-2">
        <NavLink
          to={settingsItem.to}
          onClick={onClose}
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
            <div className="flex items-center gap-3">
              <settingsItem.icon
                size={17}
                className={cn(
                  'shrink-0 transition-colors duration-200',
                  isActive ? 'text-primary' : 'text-text-muted group-hover:text-text',
                )}
              />
              <div>
                <span className={cn('block text-sm font-medium', isActive && 'text-primary')}>
                  {settingsItem.label}
                </span>
                <span className="mt-0.5 block text-xs opacity-60">{settingsItem.description}</span>
              </div>
            </div>
          )}
        </NavLink>
      </div>

      <div className="border-t border-border px-5 py-4">
        <div className="flex items-center gap-2">
          <span
            className={cn(
              'h-1.5 w-1.5 rounded-full',
              isOnline
                ? 'animate-pulse bg-success shadow-[0_0_6px_rgba(78,122,81,0.5)]'
                : 'bg-warning',
            )}
          />
          <span className="text-xs text-text-muted">
            v0.1.0 · {isOnline ? 'online' : 'offline'}
          </span>
        </div>
      </div>
    </>
  );
}

export function Sidebar({ open, onClose }: SidebarProps) {
  const drawerRef = useRef<HTMLDivElement>(null);

  // Close on Escape key
  useEffect(() => {
    if (!open) return;

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        onClose();
      }
    }

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [open, onClose]);

  // Focus first nav link when drawer opens
  useEffect(() => {
    if (open && drawerRef.current) {
      const firstLink = drawerRef.current.querySelector<HTMLElement>('a, button');
      firstLink?.focus();
    }
  }, [open]);

  // Prevent body scroll when drawer is open
  useEffect(() => {
    if (open) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [open]);

  return (
    <>
      {/* Desktop sidebar — sticky, always visible at lg+ */}
      <aside
        role="complementary"
        aria-label="Sidebar"
        className="hidden w-[220px] shrink-0 sticky top-0 h-screen flex-col overflow-y-auto border-r border-border bg-surface/80 backdrop-blur-md lg:flex"
      >
        <SidebarContent />
      </aside>

      {/* Mobile drawer overlay */}
      <div
        id="mobile-sidebar"
        aria-hidden={!open}
        className={cn(
          'fixed inset-0 z-[2000] lg:hidden',
          open ? 'pointer-events-auto' : 'pointer-events-none',
        )}
      >
        {/* Backdrop */}
        <div
          className={cn(
            'absolute inset-0 bg-black/50 backdrop-blur-sm transition-opacity duration-300',
            open ? 'opacity-100' : 'opacity-0',
          )}
          onClick={onClose}
          aria-hidden="true"
        />

        {/* Drawer panel */}
        <div
          ref={drawerRef}
          role="dialog"
          aria-modal="true"
          aria-label="Navigation menu"
          className={cn(
            'absolute left-0 top-0 flex h-full w-[260px] flex-col border-r border-border bg-surface/95 backdrop-blur-md transition-transform duration-300 ease-in-out',
            open ? 'translate-x-0' : '-translate-x-full',
          )}
        >
          <SidebarContent onClose={onClose} />
        </div>
      </div>
    </>
  );
}
