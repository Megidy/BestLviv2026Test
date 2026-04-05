import { createContext, useCallback, useEffect, useRef, useState } from 'react';
import type { PropsWithChildren } from 'react';

type NetworkContextValue = {
  isOnline: boolean;
  showOfflineToast: boolean;
  dismissOfflineToast: () => void;
};

export const NetworkContext = createContext<NetworkContextValue | null>(null);

export function NetworkProvider({ children }: PropsWithChildren) {
  const [isOnline, setIsOnline] = useState(() => navigator.onLine);
  const [showOfflineToast, setShowOfflineToast] = useState(false);
  const hasShownToast = useRef(false);

  const dismissOfflineToast = useCallback(() => {
    setShowOfflineToast(false);
  }, []);

  useEffect(() => {
    function handleOnline() {
      setIsOnline(true);
    }

    function handleOffline() {
      setIsOnline(false);
      if (!hasShownToast.current) {
        hasShownToast.current = true;
        setShowOfflineToast(true);
      }
    }

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return (
    <NetworkContext.Provider value={{ isOnline, showOfflineToast, dismissOfflineToast }}>
      {children}
    </NetworkContext.Provider>
  );
}
