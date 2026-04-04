import { useNavigate } from 'react-router-dom';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { Button } from '@/shared/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import { formatDateTime } from '@/shared/lib/formatters';

export function SettingsPage() {
  const navigate = useNavigate();
  const { user, logout } = useAuth();

  if (!user) {
    return null;
  }

  return (
    <div className="mx-auto max-w-3xl space-y-5 animate-slide-up">
      <Card>
        <CardHeader>
          <CardTitle>Profile</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-2">
          <div className="rounded-xl border border-border bg-surface/60 p-4">
            <p className="text-sm text-text-muted">Username</p>
            <p className="mt-2 text-lg font-semibold">{user.username}</p>
          </div>
          <div className="rounded-xl border border-border bg-surface/60 p-4">
            <p className="text-sm text-text-muted">Role</p>
            <p className="mt-2 text-lg font-semibold capitalize">{user.role}</p>
          </div>
          <div className="rounded-xl border border-border bg-surface/60 p-4">
            <p className="text-sm text-text-muted">Warehouse / location</p>
            <p className="mt-2 text-lg font-semibold">#{user.location_id}</p>
          </div>
          <div className="rounded-xl border border-border bg-surface/60 p-4">
            <p className="text-sm text-text-muted">Session created</p>
            <p className="mt-2 text-lg font-semibold">
              {formatDateTime(user.created_at)}
            </p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Session</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-wrap items-center justify-between gap-3">
          <p className="flex items-center gap-2 text-sm text-text-muted">
            <span className="h-1.5 w-1.5 rounded-full bg-success animate-pulse" />
            Authenticated against the live backend
          </p>
          <Button
            variant="danger"
            onClick={() => {
              logout();
              navigate('/login');
            }}
          >
            Sign out
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
