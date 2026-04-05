import type {
  DeliveryPriority,
  MapPointStatus,
  PredictiveAlert,
} from '@/shared/api';

export function formatDateTime(value?: string) {
  if (!value) {
    return 'N/A';
  }

  return new Intl.DateTimeFormat('uk-UA', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
}

export function formatRelativeCountdown(value?: string) {
  if (!value) {
    return 'N/A';
  }

  const diffMs = new Date(value).getTime() - Date.now();

  if (diffMs <= 0) {
    return 'Due now';
  }

  const totalMinutes = Math.round(diffMs / 1000 / 60);
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;

  if (hours <= 0) {
    return `${minutes}m`;
  }

  return `${hours}h ${minutes}m`;
}

export function formatPercent(value: number) {
  return `${Math.round(value * 100)}%`;
}

export function formatNumber(value: number) {
  return new Intl.NumberFormat('en-US', {
    maximumFractionDigits: 1,
  }).format(value);
}

export function mapStatusTone(status: MapPointStatus) {
  switch (status) {
    case 'critical':
      return 'danger';
    case 'elevated':
      return 'warning';
    case 'predictive':
      return 'info';
    default:
      return 'success';
  }
}

export function priorityTone(priority: DeliveryPriority) {
  switch (priority) {
    case 'urgent':
      return 'danger';
    case 'critical':
      return 'warning';
    case 'elevated':
      return 'info';
    default:
      return 'neutral';
  }
}

export function alertTone(alert: Pick<PredictiveAlert, 'confidence'>) {
  if (alert.confidence >= 0.85) {
    return 'danger';
  }

  if (alert.confidence >= 0.65) {
    return 'warning';
  }

  return 'info';
}
