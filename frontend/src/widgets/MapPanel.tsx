import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/shared/ui/Card';

type MapPanelProps = {
  title?: string;
  description?: string;
};

export function MapPanel({
  title = 'Map',
  description = 'Connect a map provider when live geospatial data is ready.',
}: MapPanelProps) {
  return (
    <Card className="h-full">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="relative flex h-80 items-center justify-center overflow-hidden rounded-xl border border-border bg-background/60">
          {/* Grid pattern */}
          <div
            className="absolute inset-0 opacity-[0.04]"
            style={{
              backgroundImage:
                'linear-gradient(rgba(254,250,246,0.08) 1px, transparent 1px), linear-gradient(90deg, rgba(254,250,246,0.08) 1px, transparent 1px)',
              backgroundSize: '40px 40px',
            }}
          />
          {/* Glow dots */}
          <div className="absolute left-1/3 top-1/3 h-3 w-3 animate-pulse-glow rounded-full bg-primary/50" />
          <div className="absolute bottom-1/4 right-1/3 h-2 w-2 animate-pulse rounded-full bg-success/60" />
          <div className="absolute left-2/3 top-1/2 h-2.5 w-2.5 animate-pulse rounded-full bg-warning/50" />
          <span className="relative z-10 text-sm text-text-muted/60">
            Interactive map area
          </span>
        </div>
      </CardContent>
    </Card>
  );
}
