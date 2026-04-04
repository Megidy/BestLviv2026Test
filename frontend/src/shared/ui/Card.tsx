import type { HTMLAttributes } from 'react';

import { cn } from '@/shared/lib/cn';

export function Card({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        'rounded-2xl border border-border bg-panel/80 shadow-card backdrop-blur-sm transition-shadow duration-300 hover:shadow-card-hover',
        className,
      )}
      {...props}
    />
  );
}

export function CardHeader({
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('space-y-2 p-5 pb-3', className)} {...props} />;
}

export function CardTitle({
  className,
  ...props
}: HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h2
      className={cn('text-lg font-semibold text-text', className)}
      {...props}
    />
  );
}

export function CardDescription({
  className,
  ...props
}: HTMLAttributes<HTMLParagraphElement>) {
  return <p className={cn('text-sm text-text-muted', className)} {...props} />;
}

export function CardContent({
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('p-5 pt-2', className)} {...props} />;
}
