import type { HTMLAttributes } from 'react';

import { cn } from '@/shared/lib/cn';

type BadgeProps = HTMLAttributes<HTMLSpanElement> & {
  tone?: 'neutral' | 'success' | 'warning' | 'danger' | 'info';
};

const toneClasses: Record<NonNullable<BadgeProps['tone']>, string> = {
  neutral: 'bg-accent text-text-muted border border-border',
  success:
    'bg-success/15 text-success border border-success/20 shadow-[0_0_8px_rgba(78,122,81,0.1)]',
  warning:
    'bg-warning/15 text-warning border border-warning/20 shadow-[0_0_8px_rgba(169,122,32,0.1)]',
  danger:
    'bg-danger/15 text-danger border border-danger/20 shadow-[0_0_8px_rgba(160,69,53,0.1)]',
  info: 'bg-info/15 text-info border border-info/20 shadow-[0_0_8px_rgba(66,105,143,0.1)]',
};

export function Badge({ className, tone = 'neutral', ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium capitalize transition-colors',
        toneClasses[tone],
        className,
      )}
      {...props}
    />
  );
}
