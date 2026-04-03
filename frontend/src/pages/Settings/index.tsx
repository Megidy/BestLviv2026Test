import { Button } from '@/shared/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import { Input } from '@/shared/ui/Input';

export function SettingsPage() {
  return (
    <div className="mx-auto max-w-3xl space-y-5 animate-slide-up">
      <Card>
        <CardHeader>
          <CardTitle>Profile</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
            <label className="text-sm text-text-muted" htmlFor="name">
              Name
            </label>
            <Input defaultValue="Operator Ivanov" id="name" />
          </div>
          <div className="space-y-2">
            <label className="text-sm text-text-muted" htmlFor="email">
              Email
            </label>
            <Input defaultValue="ivanov@logisync.io" id="email" type="email" />
          </div>
          <div className="space-y-2">
            <label className="text-sm text-text-muted" htmlFor="role">
              Role
            </label>
            <Input defaultValue="Operator" id="role" disabled />
          </div>
          <div className="space-y-2">
            <label className="text-sm text-text-muted" htmlFor="timezone">
              Time zone
            </label>
            <Input defaultValue="Europe/Kyiv" id="timezone" />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Password</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
            <label className="text-sm text-text-muted" htmlFor="current-password">
              Current password
            </label>
            <Input placeholder="••••••••" type="password" id="current-password" />
          </div>
          <div className="space-y-2">
            <label className="text-sm text-text-muted" htmlFor="new-password">
              New password
            </label>
            <Input placeholder="••••••••" type="password" id="new-password" />
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
            Active session since 02.04.2026, 08:00
          </p>
          <div className="flex gap-3">
            <Button variant="outline">Save changes</Button>
            <Button variant="danger">Sign out</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
