import {
  cloneElement,
  isValidElement,
  type ButtonHTMLAttributes,
  type ReactElement,
  type ReactNode,
} from 'react';

import { cn } from '@/shared/lib/cn';

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  asChild?: boolean;
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  children: ReactNode;
};

const variantClasses: Record<NonNullable<ButtonProps['variant']>, string> = {
  primary:
    'bg-primary text-primary-foreground hover:bg-primary/85 shadow-glow hover:shadow-[0_0_28px_rgba(145,98,29,0.3)] active:scale-[0.97]',
  secondary:
    'bg-panel text-text hover:bg-accent border border-border active:scale-[0.97]',
  outline:
    'border border-border bg-transparent text-text hover:bg-accent hover:border-primary/30 active:scale-[0.97]',
  ghost:
    'bg-transparent text-text-muted hover:bg-accent hover:text-text active:scale-[0.97]',
  danger:
    'bg-danger text-primary-foreground hover:bg-danger/85 shadow-[0_0_16px_rgba(160,69,53,0.2)] active:scale-[0.97]',
};

const sizeClasses: Record<NonNullable<ButtonProps['size']>, string> = {
  sm: 'h-9 px-3.5 text-sm',
  md: 'h-10 px-5 text-sm',
  lg: 'h-11 px-6 text-sm',
};

export function Button({
  asChild = false,
  className,
  variant = 'primary',
  size = 'md',
  children,
  ...props
}: ButtonProps) {
  const classes = cn(
    'inline-flex items-center justify-center rounded-xl font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60 disabled:cursor-not-allowed disabled:opacity-50',
    variantClasses[variant],
    sizeClasses[size],
    className,
  );

  if (asChild && isValidElement(children)) {
    return cloneElement(children as ReactElement<{ className?: string }>, {
      className: cn(
        classes,
        (children as ReactElement<{ className?: string }>).props.className,
      ),
    });
  }

  return (
    <button className={classes} {...props}>
      {children}
    </button>
  );
}
