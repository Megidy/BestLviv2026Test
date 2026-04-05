type SkeletonProps = {
  className?: string;
};

export function Skeleton({ className = '' }: SkeletonProps) {
  return (
    <div
      aria-hidden="true"
      className={`relative overflow-hidden rounded-md bg-accent before:absolute before:inset-0 before:-translate-x-full before:animate-shimmer before:bg-gradient-to-r before:from-transparent before:via-white/5 before:to-transparent ${className}`}
    />
  );
}

/** A full table row of skeletons — pass colWidths as Tailwind width classes per cell */
export function SkeletonRow({ cols }: { cols: string[] }) {
  return (
    <tr aria-hidden="true">
      {cols.map((w, i) => (
        <td key={i} className="px-4 py-3">
          <Skeleton className={`h-4 ${w}`} />
        </td>
      ))}
    </tr>
  );
}
