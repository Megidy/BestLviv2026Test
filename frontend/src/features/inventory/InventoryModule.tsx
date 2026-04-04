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
                  <TableCell className="text-text-muted">
                    {item.category}
                  </TableCell>
                  <TableCell className="text-right font-semibold">
                    {formatNumber(item.quantity)}
                  </TableCell>
                  <TableCell className="text-right text-text-muted">
                    {formatNumber(item.allocatableQuantity)}
                  </TableCell>
                  <TableCell className="text-right text-text-muted">
                    {formatNumber(item.safetyStock)}
                  </TableCell>
                  <TableCell className="text-text-muted">{item.unit}</TableCell>
                  <TableCell className="text-right text-text-muted">
                    {formatDateTime(item.updatedAt)}
                  </TableCell>
                </TableRow>
                ))
              )}
            </TableBody>
          </Table>
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
            onClick={() =>
              setPage((current) => Math.min(current + 1, totalPages))
            }
          >
            Next
          </Button>
        </div>
      </div>
    </div>
  );
}
