import { useMemo, useState } from 'react';

import { auditLog } from '@/shared/config/operations-data';
import { Button } from '@/shared/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import { Input } from '@/shared/ui/Input';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/shared/ui/Table';

export function AdminPage() {
  const [search, setSearch] = useState('');

  const filteredEntries = useMemo(
    () =>
      auditLog.filter((entry) =>
        [entry.user, entry.action, entry.entity].some((value) =>
          value.toLowerCase().includes(search.toLowerCase()),
        ),
      ),
    [search],
  );

  return (
    <div className="space-y-5 animate-slide-up">
      <div className="flex items-center gap-3">
        <div className="w-full max-w-sm">
          <Input
            placeholder="Search audit log…"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
        </div>
        <Button variant="outline" size="sm">
          Export CSV
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Audit log</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>Role</TableHead>
                <TableHead>Action</TableHead>
                <TableHead>Entity</TableHead>
                <TableHead>Before</TableHead>
                <TableHead>After</TableHead>
                <TableHead className="text-right">Timestamp</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredEntries.map((entry) => (
                <TableRow key={entry.id} className="hover:bg-accent/60">
                  <TableCell className="font-medium">{entry.user}</TableCell>
                  <TableCell className="text-text-muted">
                    {entry.role}
                  </TableCell>
                  <TableCell>{entry.action}</TableCell>
                  <TableCell>{entry.entity}</TableCell>
                  <TableCell className="text-text-muted">
                    {entry.before}
                  </TableCell>
                  <TableCell>{entry.after}</TableCell>
                  <TableCell className="text-right text-text-muted">
                    {entry.timestamp}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
