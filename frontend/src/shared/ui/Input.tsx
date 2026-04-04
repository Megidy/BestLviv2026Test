import type { InputHTMLAttributes } from 'react';

import { cn } from '@/shared/lib/cn';

type InputProps = InputHTMLAttributes<HTMLInputElement>;

export function Input({ className, ...props }: InputProps) {
  return (
    <input
      className={cn(
        'h-10 w-full rounded-xl border border-border bg-surface/80 px-4 text-sm text-text outline-none backdrop-blur-sm transition-all duration-200 placeholder:text-text-muted/60 focus:border-primary/60 focus:ring-2 focus:ring-primary/20 disabled:cursor-not-allowed disabled:opacity-50',
        className,
      )}
      {...props}
    />
  );
}
