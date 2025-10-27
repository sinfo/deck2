/* eslint-disable @typescript-eslint/no-explicit-any */
export const env = {
  API_URL:
    ((window as any)._env_?.VITE_API_URL as string) ||
    import.meta.env.VITE_API_URL,
  GOOGLE_CLIENT_ID:
    ((window as any)._env_?.VITE_GOOGLE_CLIENT_ID as string) ||
    import.meta.env.VITE_GOOGLE_CLIENT_ID,
  GOOGLE_SCOPE:
    ((window as any)._env_?.VITE_GOOGLE_SCOPE as string) ||
    import.meta.env.VITE_GOOGLE_SCOPE,
};
