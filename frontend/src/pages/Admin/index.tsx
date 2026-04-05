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
          {/* Mobile card list — hidden on lg+ */}
          <div className="space-y-3 lg:hidden">
            {isLoading ? (
              <p className="py-10 text-center text-sm text-text-muted">Loading audit log…</p>
            ) : error ? (
              <p className="py-10 text-center text-sm text-danger">{error}</p>
            ) : filteredEntries.length === 0 ? (
              <p className="py-10 text-center text-sm text-text-muted">No audit entries match the current search.</p>
            ) : (
              filteredEntries.map((entry) => (
                <div
                  key={entry.id}
                  className="rounded-xl border border-border bg-surface/50 p-4"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-text">
                        {entry.actor_id ? `User #${entry.actor_id}` : 'System'}
                      </p>
                      <p className="mt-0.5 text-xs capitalize text-text-muted">{entry.actor_role}</p>
                    </div>
                    <span className="shrink-0 rounded-lg border border-border px-2 py-0.5 text-xs text-text-muted">
                      {entry.action}
                    </span>
                  </div>

                  <div className="mt-3 grid grid-cols-2 gap-2 text-xs">
                    <div>
                      <p className="text-text-muted">Entity type</p>
                      <p className="mt-0.5 text-text">{entry.entity_type ?? 'N/A'}</p>
                    </div>
                    <div>
                      <p className="text-text-muted">Entity ID</p>
                      <p className="mt-0.5 text-text">{entry.entity_id ?? 'N/A'}</p>
                    </div>
                    {entry.before_value ? (
                      <div className="col-span-2">
                        <p className="text-text-muted">Before</p>
                        <p className="mt-0.5 truncate text-text">{entry.before_value}</p>
                      </div>
                    ) : null}
                    {entry.after_value ? (
                      <div className="col-span-2">
                        <p className="text-text-muted">After</p>
                        <p className="mt-0.5 truncate text-text">{entry.after_value}</p>
                      </div>
                    ) : null}
                    <div className="col-span-2">
                      <p className="text-text-muted">Timestamp</p>
                      <p className="mt-0.5 text-text">{formatDateTime(entry.created_at)}</p>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>

          {/* Desktop table — hidden on mobile/tablet */}
          <div className="hidden lg:block">
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
                      <TableCell className="text-text-muted">{entry.actor_role}</TableCell>
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
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
