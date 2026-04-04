import { Navigate, Outlet } from 'react-router-dom';

import { useAuth } from '@/features/auth/hooks/useAuth';

type AuthGuardProps = {
  requireAuth?: boolean;
};

export function AuthGuard({ requireAuth = true }: AuthGuardProps) {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-sm text-text-muted">
        Loading session…
      </div>
    );
  }

  if (requireAuth && !isAuthenticated) {
    return <Navigate replace to="/login" />;
  }

  if (!requireAuth && isAuthenticated) {
    return <Navigate replace to="/dashboard" />;
  }

  return <Outlet />;
}
