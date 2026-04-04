import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type PropsWithChildren,
} from 'react';

import {
  ApiError,
  clearAccessToken,
  endpoints,
  request,
  setAccessToken,
  unwrapApiResponse,
  type ApiResponse,
  type User,
} from '@/shared/api';

type AuthContextValue = {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
  refreshMe: () => Promise<User | null>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

async function fetchCurrentUser() {
  const response = await request<ApiResponse<User>>(endpoints.auth.me);
  return unwrapApiResponse(response);
}

export function AuthProvider({ children }: PropsWithChildren) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const logout = useCallback(() => {
    clearAccessToken();
    setUser(null);
    setError(null);
  }, []);

  const refreshMe = useCallback(async () => {
    try {
      const currentUser = await fetchCurrentUser();
      setUser(currentUser);
      setError(null);
      return currentUser;
    } catch (caught) {
      if (caught instanceof ApiError && caught.statusCode === 401) {
        logout();
        return null;
      }

      const message =
        caught instanceof Error ? caught.message : 'Failed to load session';
      setError(message);
      throw caught;
    }
  }, [logout]);

  const login = useCallback(
    async (username: string, password: string) => {
      setError(null);

      const response = await request<ApiResponse<string>>(endpoints.auth.login, {
        method: 'POST',
        body: { username, password },
      });

      setAccessToken(unwrapApiResponse(response));
      await refreshMe();
    },
    [refreshMe],
  );

  useEffect(() => {
    let active = true;

    async function bootstrap() {
      try {
        await refreshMe();
      } catch {
        // Errors are already reflected in state.
      } finally {
        if (active) {
          setIsLoading(false);
        }
      }
    }

    bootstrap();

    return () => {
      active = false;
    };
  }, [refreshMe]);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isAuthenticated: user !== null,
      isLoading,
      error,
      login,
      logout,
      refreshMe,
    }),
    [error, isLoading, login, logout, refreshMe, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuthContext() {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error('useAuthContext must be used within AuthProvider');
  }

  return context;
}
