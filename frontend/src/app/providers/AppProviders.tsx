import type { PropsWithChildren } from 'react';

import { AuthProvider } from '@/features/auth/AuthProvider';
import { NetworkProvider } from '@/shared/providers/NetworkProvider';

export function AppProviders({ children }: PropsWithChildren) {
  return (
    <NetworkProvider>
      <AuthProvider>{children}</AuthProvider>
    </NetworkProvider>
  );
}
