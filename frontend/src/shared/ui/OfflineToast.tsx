import { useEffect } from 'react';
import { WifiOff } from 'lucide-react';

import { useNetwork } from '@/shared/hooks/useNetwork';

export function OfflineToast() {
  const { showOfflineToast, dismissOfflineToast } = useNetwork();

  useEffect(() => {
    if (!showOfflineToast) return;
    const timer = setTimeout(dismissOfflineToast, 5000);
    return () => clearTimeout(timer);
  }, [showOfflineToast, dismissOfflineToast]);

  if (!showOfflineToast) return null;

  return (
    <div
      role="status"
      aria-live="polite"
      className="fixed bottom-6 left-1/2 z-[9999] -translate-x-1/2 animate-fade-in"
    >
      <div className="flex items-center gap-3 rounded-xl border border-warning/30 bg-surface/95 px-4 py-3 shadow-lg backdrop-blur-md">
        <WifiOff size={16} className="shrink-0 text-warning" />
        <p className="text-sm text-text">
          You&rsquo;re offline &mdash; viewing cached data
        </p>
        <button
          type="button"
          onClick={dismissOfflineToast}
          className="ml-1 text-xs text-text-muted transition-colors hover:text-text focus-visible:outline-none"
          aria-label="Dismiss"
        >
          ✕
        </button>
      </div>
    </div>
  );
}
