import { MapView } from '@/features/map/MapView';
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
  description = 'Live warehouses and customer points from the backend.',
}: MapPanelProps) {
  return (
    <Card className="h-full">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent className="h-[26rem]">
        <div className="h-full overflow-hidden rounded-xl">
          <MapView />
        </div>
      </CardContent>
    </Card>
  );
}
