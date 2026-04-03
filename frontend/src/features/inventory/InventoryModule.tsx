import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';

import { inventoryItems } from '@/shared/config/operations-data';
import { Badge } from '@/shared/ui/Badge';
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

const categories = [
  'all',
  ...new Set(inventoryItems.map((item) => item.category)),
];

export function InventoryModule() {
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('all');

  const filteredItems = useMemo(
    () =>
      inventoryItems.filter((item) => {
        const matchesSearch = item.name
          .toLowerCase()
          .includes(search.toLowerCase());
        const matchesCategory =
          category === 'all' || item.category === category;

        return matchesSearch && matchesCategory;
      }),
    [category, search],
  );

  return (
    <div className="space-y-5 animate-slide-up">
      <div className="flex flex-wrap items-center gap-3">
        <div className="w-full max-w-sm">
          <Input
            placeholder="Search resource…"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
        </div>

        <div className="flex flex-wrap gap-2">
          {categories.map((item) => (
            <Button
              key={item}
              variant={category === item ? 'primary' : 'ghost'}
              size="sm"
              onClick={() => setCategory(item)}
            >
              {item === 'all' ? 'All' : item}
            </Button>
          ))}
        </div>

        <Button className="ml-auto" size="sm" variant="outline">
          Export CSV
        </Button>
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
                <TableHead>Unit</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Location</TableHead>
                <TableHead className="text-right">Updated</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredItems.map((item) => (
                <TableRow key={item.id} className="hover:bg-accent/60">
                  <TableCell className="font-medium">
                    <Link
                      to={`/resource/${item.id}`}
                      className="transition-colors hover:text-primary"
                    >
                      {item.name}
                    </Link>
                  </TableCell>
                  <TableCell className="text-text-muted">
                    {item.category}
                  </TableCell>
                  <TableCell className="text-right font-semibold">
                    {item.quantity}
                  </TableCell>
                  <TableCell className="text-text-muted">{item.unit}</TableCell>
                  <TableCell>
                    <Badge tone={item.tone}>{item.tone}</Badge>
                  </TableCell>
                  <TableCell className="text-text-muted">
                    {item.location}
                  </TableCell>
                  <TableCell className="text-right text-text-muted">
                    {item.updated}
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
