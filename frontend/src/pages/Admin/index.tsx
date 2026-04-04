import { useEffect, useMemo, useState } from 'react';

import { endpoints, request, unwrapApiResponse, type ApiResponse, type AuditLogResponse } from '@/shared/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import { formatDateTime } from '@/shared/lib/formatters';
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
  const [entries, setEntries] = useState<AuditLogResponse['entries']>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;

    async function loadAuditLog() {
      try {
        const response = await request<ApiResponse<AuditLogResponse>>(
          endpoints.audit.list,
          {
            query: {
              page: 1,
              pageSize: 50,
            },
          },
        );

        if (active) {
          const data = unwrapApiResponse(response);
          setEntries(Array.isArray(data?.entries) ? data.entries : []);
          setError(null);
        }
      } catch (caught) {
        if (active) {
          setEntries([]);
          setError(
            caught instanceof Error ? caught.message : 'Failed to load audit log',
          );
        }
      } finally {
        if (active) {
          setIsLoading(false);
        }
      }
    }

    void loadAuditLog();

    return () => {
      active = false;
    };
  }, []);

  const filteredEntries = useMemo(
    () =>
      (entries ?? []).filter((entry) =>
        [
          String(entry.actor_id ?? ''),
          entry.actor_role,
          entry.action,
          entry.entity_type ?? '',
        ].some((value) =>
          value.toLowerCase().includes(search.toLowerCase()),
        ),
      ),
    [entries, search],
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
                <TableHead>Entity type</TableHead>
                <TableHead>Entity ID</TableHead>
                <TableHead>Before</TableHead>
                <TableHead>After</TableHead>
                <TableHead className="text-right">Timestamp</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell className="py-10 text-center text-text-muted" colSpan={8}>
                    Loading audit log…
                  </TableCell>
                </TableRow>
              ) : error ? (
                <TableRow>
                  <TableCell className="py-10 text-center text-danger" colSpan={8}>
                    {error}
                  </TableCell>
                </TableRow>
              ) : filteredEntries.length === 0 ? (
                <TableRow>
                  <TableCell className="py-10 text-center text-text-muted" colSpan={8}>
                    No audit entries match the current search.
                  </TableCell>
                </TableRow>
              ) : (
                filteredEntries.map((entry) => (
                <TableRow key={entry.id} className="hover:bg-accent/60">
                  <TableCell className="font-medium">
                    {entry.actor_id ? `User #${entry.actor_id}` : 'System'}
                  </TableCell>
                  <TableCell className="text-text-muted">
                    {entry.actor_role}
                  </TableCell>
                  <TableCell>{entry.action}</TableCell>
                  <TableCell>{entry.entity_type ?? 'N/A'}</TableCell>
                  <TableCell>{entry.entity_id ?? 'N/A'}</TableCell>
                  <TableCell className="max-w-48 truncate text-text-muted">
                    {entry.before_value ?? 'N/A'}
                  </TableCell>
                  <TableCell className="max-w-48 truncate">
                    {entry.after_value ?? 'N/A'}
                  </TableCell>
                  <TableCell className="text-right text-text-muted">
                    {formatDateTime(entry.created_at)}
                  </TableCell>
                </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
