export const API_URL = '/v1';

export const apiClient = async <T>(endpoint: string, options?: RequestInit): Promise<T> => {
  const token = localStorage.getItem('token');
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(token && { Authorization: `Bearer ${token}` }),
    ...options?.headers,
  };

  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.metadata?.message || 'API Request Failed');
  }

  const data = await response.json();
  return data as T;
};
