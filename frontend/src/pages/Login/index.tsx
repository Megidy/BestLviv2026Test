import { Link } from 'react-router-dom';

import { Button } from '@/shared/ui/Button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/shared/ui/Card';
import { Input } from '@/shared/ui/Input';

export function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-background px-6 py-10 text-text">
      <div className="w-full max-w-md animate-slide-up">
        <Card>
          <CardHeader>
            <div className="mb-3 flex items-center gap-2.5">
              <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/20 shadow-glow">
                <span className="text-base font-bold text-primary">L</span>
              </div>
              <span className="text-sm font-semibold tracking-wide text-text">
                Logisync
              </span>
            </div>
            <CardTitle>Sign in</CardTitle>
            <CardDescription>
              Enter your credentials to access the operations hub.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm text-text-muted" htmlFor="login-email">
                Email
              </label>
              <Input placeholder="name@company.com" type="email" id="login-email" />
            </div>
            <div className="space-y-2">
              <label className="text-sm text-text-muted" htmlFor="login-password">
                Password
              </label>
              <Input placeholder="••••••••" type="password" id="login-password" />
            </div>
            <Button asChild className="w-full">
              <Link to="/dashboard">Continue</Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    </main>
  );
}
