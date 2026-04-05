import { API_BASE_URL } from '@/shared/api/endpoints';
import type { ApiMetadata, ApiResponse } from '@/shared/api/types';

const TOKEN_STORAGE_KEY = 'auth_token';

let accessToken =
  typeof window === 'undefined'
    ? null
    : window.localStorage.getItem(TOKEN_STORAGE_KEY);

export class ApiError extends Error {
  statusCode: number;
  metadata?: ApiMetadata;

  constructor(message: string, statusCode: number, metadata?: ApiMetadata) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.metadata = metadata;
  }
}

type RequestOptions = Omit<RequestInit, 'body'> & {
  body?: BodyInit | Record<string, unknown> | null;
  query?: Record<string, string | number | boolean | undefined | null>;
};

function isApiResponse<T>(value: unknown): value is ApiResponse<T> {
  return typeof value === 'object' && value !== null && 'metadata' in value;
}

function buildUrl(
  endpoint: string,
  query?: Record<string, string | number | boolean | undefined | null>,
) {
  const url = new URL(endpoint, API_BASE_URL);

  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value === undefined || value === null || value === '') {
        continue;
      }

      url.searchParams.set(key, String(value));
    }
  }

  return url.toString();
}

async function parseBody(response: Response) {
  const contentType = response.headers.get('content-type') ?? '';

  if (response.status === 204 || !contentType.includes('application/json')) {
    return null;
  }

  return response.json();
}

export function getAccessToken() {
  return accessToken;
}

export function setAccessToken(token: string) {
  accessToken = token;
  window.localStorage.setItem(TOKEN_STORAGE_KEY, token);
}

export function clearAccessToken() {
  accessToken = null;
  window.localStorage.removeItem(TOKEN_STORAGE_KEY);
}

export async function request<T>(
  endpoint: string,
  { body, headers, query, ...init }: RequestOptions = {},
): Promise<T> {
  const method = (init.method ?? 'GET').toUpperCase();
  if (!navigator.onLine && method !== 'GET') {
    throw new ApiError('Not available offline', 0);
  }

  const payload =
    body && typeof body === 'object' && !(body instanceof FormData)
      ? JSON.stringify(body)
      : body;

  const response = await fetch(buildUrl(endpoint, query), {
    ...init,
    body: payload,
    headers: {
      ...(payload && !(body instanceof FormData)
        ? { 'Content-Type': 'application/json' }
        : {}),
      ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
      ...headers,
    },
  });

  const parsed = await parseBody(response);

  if (!response.ok) {
    const metadata = isApiResponse(parsed) ? parsed.metadata : undefined;

    if (response.status === 401) {
      window.dispatchEvent(new CustomEvent('auth:unauthorized'));
    }

    throw new ApiError(
      metadata?.error ?? metadata?.message ?? 'Request failed',
      response.status,
      metadata,
    );
  }

  return parsed as T;
}

export function unwrapApiResponse<T>(response: ApiResponse<T>) {
  return response.data;
}
