import { useEffect, useMemo, useState } from 'react';
import { ChevronUp, ChevronDown, ChevronsUpDown } from 'lucide-react';
import { Link } from 'react-router-dom';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { Button } from '@/shared/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import { Input } from '@/shared/ui/Input';
import { Skeleton, SkeletonRow } from '@/shared/ui/Skeleton';
import { formatDateTime, formatNumber } from '@/shared/lib/formatters';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/shared/ui/Table';

type SortKey = 'quantity' | 'allocatableQuantity' | 'safetyStock';
type SortDir = 'asc' | 'desc';

function SortIcon({ active, dir }: { active: boolean; dir: SortDir }) {
  if (!active) return <ChevronsUpDown size={12} className="ml-1 inline opacity-40" />;
  return dir === 'asc'
    ? <ChevronUp size={12} className="ml-1 inline text-primary" />
    : <ChevronDown size={12} className="ml-1 inline text-primary" />;
}

export function InventoryModule() {
  const { user } = useAuth();
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('all');
  const [page, setPage] = useState(1);
  const [sortKey, setSortKey] = useState<SortKey | null>(null);
  const [sortDir, setSortDir] = useState<SortDir>('desc');
  const [allCategories, setAllCategories] = useState<string[]>(['all']);
  const pageSize = 12;

  // Unfiltered load just to get stable category list
  const { items: allItems } = useInventory({
    enabled: Boolean(user?.location_id),
    locationId: user?.location_id ?? 0,
    page: 1,
    pageSize: 50,
  });

  useEffect(() => {
    if (allItems.length > 0) {
      setAllCategories(['all', ...new Set(allItems.map((item) => item.category))]);
    }
  }, [allItems]);

  const { items, total, isLoading, error } = useInventory({
    enabled: Boolean(user?.location_id),
    locationId: user?.location_id ?? 0,
    resourceName: search,
    category,
    page,
    pageSize,
  });
  const totalPages = Math.max(Math.ceil(total / pageSize), 1);

  function toggleSort(key: SortKey) {
    if (sortKey === key) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortKey(key);
      setSortDir('desc');
    }
  }

  const displayedItems = useMemo(() => {
    if (!sortKey) return items;
    return [...items].sort((a, b) => {
      const diff = a[sortKey] - b[sortKey];
      return sortDir === 'asc' ? diff : -diff;
    });
  }, [items, sortKey, sortDir]);

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
          {allCategories.map((categoryOption) => (
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
              Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="rounded-xl border border-border bg-surface/50 p-4">
                  <div className="flex items-start justify-between gap-2">
                    <Skeleton className="h-4 w-32" />
                    <Skeleton className="h-5 w-16" />
                  </div>
                  <div className="mt-3 grid grid-cols-2 gap-3">
                    {Array.from({ length: 4 }).map((__, j) => (
                      <div key={j}>
                        <Skeleton className="h-3 w-16 mb-1" />
                        <Skeleton className="h-4 w-24" />
                      </div>
                    ))}
                  </div>
                </div>
              ))
            ) : error ? (
              <p className="py-10 text-center text-sm text-danger">{error}</p>
            ) : items.length === 0 ? (
              <p className="py-10 text-center text-sm text-text-muted">No inventory matches the current filters or you are not in a warehouse.</p>
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
                  <TableHead
                    className="cursor-pointer select-none text-right hover:text-text"
                    onClick={() => toggleSort('quantity')}
                  >
                    Quantity <SortIcon active={sortKey === 'quantity'} dir={sortDir} />
                  </TableHead>
                  <TableHead
                    className="cursor-pointer select-none text-right hover:text-text"
                    onClick={() => toggleSort('allocatableQuantity')}
                  >
                    Available <SortIcon active={sortKey === 'allocatableQuantity'} dir={sortDir} />
                  </TableHead>
                  <TableHead
                    className="cursor-pointer select-none text-right hover:text-text"
                    onClick={() => toggleSort('safetyStock')}
                  >
                    Safety stock <SortIcon active={sortKey === 'safetyStock'} dir={sortDir} />
                  </TableHead>
                  <TableHead>Unit</TableHead>
                  <TableHead className="text-right">Updated</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  Array.from({ length: 7 }).map((_, i) => (
                    <SkeletonRow key={i} cols={['w-32', 'w-20', 'w-16', 'w-16', 'w-16', 'w-12', 'w-24']} />
                  ))
                ) : error ? (
                  <TableRow>
                    <TableCell className="py-10 text-center text-danger" colSpan={7}>
                      {error}
                    </TableCell>
                  </TableRow>
                ) : items.length === 0 ? (
                  <TableRow>
                    <TableCell className="py-10 text-center text-text-muted" colSpan={7}>
                      No inventory matches the current filters or you are not in a warehouse.
                    </TableCell>
                  </TableRow>
                ) : (
                  displayedItems.map((item) => (
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
