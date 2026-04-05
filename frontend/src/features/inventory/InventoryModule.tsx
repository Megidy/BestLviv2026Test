import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { Button } from '@/shared/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import { Input } from '@/shared/ui/Input';
import { formatDateTime, formatNumber } from '@/shared/lib/formatters';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/shared/ui/Table';

export function InventoryModule() {
  const { user } = useAuth();
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('all');
  const [page, setPage] = useState(1);
  const pageSize = 12;

  const { items, total, isLoading, error } = useInventory({
    enabled: Boolean(user?.location_id),
    locationId: user?.location_id ?? 0,
    resourceName: search,
    category,
    page,
    pageSize,
  });

  const categories = useMemo(
    () => ['all', ...new Set(items.map((item) => item.category))],
    [items],
  );
  const totalPages = Math.max(Math.ceil(total / pageSize), 1);

  return (
    <div className="space-y-5 animate-slide-up">
      <div className="flex flex-wrap items-center gap-3">
        <div className="w-full max-w-sm">
          <Input
            placeholder="Search resource…"
            value={search}
            onChange={(event) => {
              setPage(1);
              setSearch(event.target.value);
            }}
          />
        </div>

        <div className="flex flex-wrap gap-2">
          {categories.map((categoryOption) => (
            <Button
              key={categoryOption}
              variant={category === categoryOption ? 'primary' : 'ghost'}
              size="sm"
              onClick={() => {
                setPage(1);
                setCategory(categoryOption);
              }}
            >
              {categoryOption === 'all' ? 'All' : categoryOption}
            </Button>
          ))}
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Inventory list</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Mobile card list — hidden on md+ */}
          <div className="space-y-3 md:hidden">
            {isLoading ? (
              <p className="py-10 text-center text-sm text-text-muted">Loading inventory…</p>
            ) : error ? (
              <p className="py-10 text-center text-sm text-danger">{error}</p>
            ) : items.length === 0 ? (
              <p className="py-10 text-center text-sm text-text-muted">No inventory matches the current filters.</p>
            ) : (
              items.map((item) => (
                <div
                  key={item.inventoryId}
                  className="rounded-xl border border-border bg-surface/50 p-4"
                >
                  <div className="flex items-start justify-between gap-2">
                    <Link
                      to={`/resource/${item.resourceId}`}
                      className="text-sm font-semibold text-text transition-colors hover:text-primary"
                    >
                      {item.name}
                    </Link>
                    <span className="shrink-0 rounded-lg border border-border px-2 py-0.5 text-xs text-text-muted">
                      {item.category}
                    </span>
                  </div>
                  <div className="mt-3 grid grid-cols-2 gap-2 text-xs">
                    <div>
                      <p className="text-text-muted">Quantity</p>
                      <p className="mt-0.5 font-semibold text-text">{formatNumber(item.quantity)} {item.unit}</p>
                    </div>
                    <div>
                      <p className="text-text-muted">Available</p>
                      <p className="mt-0.5 text-text">{formatNumber(item.allocatableQuantity)} {item.unit}</p>
                    </div>
                    <div>
                      <p className="text-text-muted">Safety stock</p>
                      <p className="mt-0.5 text-text">{formatNumber(item.safetyStock)} {item.unit}</p>
                    </div>
                    <div>
                      <p className="text-text-muted">Updated</p>
                      <p className="mt-0.5 text-text">{formatDateTime(item.updatedAt)}</p>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>

          {/* Desktop table — hidden on mobile */}
          <div className="hidden md:block">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Resource</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead className="text-right">Quantity</TableHead>
                  <TableHead className="text-right">Available</TableHead>
                  <TableHead className="text-right">Safety stock</TableHead>
                  <TableHead>Unit</TableHead>
                  <TableHead className="text-right">Updated</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell className="py-10 text-center text-text-muted" colSpan={7}>
                      Loading inventory…
                    </TableCell>
                  </TableRow>
                ) : error ? (
                  <TableRow>
                    <TableCell className="py-10 text-center text-danger" colSpan={7}>
                      {error}
                    </TableCell>
                  </TableRow>
                ) : items.length === 0 ? (
                  <TableRow>
                    <TableCell className="py-10 text-center text-text-muted" colSpan={7}>
                      No inventory matches the current filters.
                    </TableCell>
                  </TableRow>
                ) : (
                  items.map((item) => (
                    <TableRow key={item.inventoryId} className="hover:bg-accent/60">
                      <TableCell className="font-medium">
                        <Link
                          to={`/resource/${item.resourceId}`}
                          className="transition-colors hover:text-primary"
                        >
                          {item.name}
                        </Link>
                      </TableCell>
                      <TableCell className="text-text-muted">{item.category}</TableCell>
                      <TableCell className="text-right font-semibold">{formatNumber(item.quantity)}</TableCell>
                      <TableCell className="text-right text-text-muted">{formatNumber(item.allocatableQuantity)}</TableCell>
                      <TableCell className="text-right text-text-muted">{formatNumber(item.safetyStock)}</TableCell>
                      <TableCell className="text-text-muted">{item.unit}</TableCell>
                      <TableCell className="text-right text-text-muted">{formatDateTime(item.updatedAt)}</TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      <div className="flex items-center justify-between gap-3">
        <p className="text-sm text-text-muted">
          Page {page} of {totalPages}
        </p>
        <div className="flex gap-2">
          <Button
            variant="ghost"
            size="sm"
            disabled={page <= 1}
            onClick={() => setPage((current) => Math.max(current - 1, 1))}
          >
            Previous
          </Button>
          <Button
            variant="ghost"
            size="sm"
            disabled={page >= totalPages}
            onClick={() => setPage((current) => Math.min(current + 1, totalPages))}
          >
            Next
          </Button>
        </div>
      </div>
    </div>
  );
}
