/* eslint-disable @typescript-eslint/no-explicit-any */
const defaultScope =
  "email profile openid https://www.googleapis.com/auth/gmail.compose https://www.googleapis.com/auth/gmail.readonly";

const rawScope =
  ((window as any)._env_?.VITE_GOOGLE_SCOPE as string) ||
  import.meta.env.VITE_GOOGLE_SCOPE ||
  defaultScope;

const googleScope = rawScope.includes("gmail.readonly")
  ? rawScope
  : `${rawScope} https://www.googleapis.com/auth/gmail.readonly`.trim();

export const env = {
  API_URL:
    ((window as any)._env_?.VITE_API_URL as string) ||
    import.meta.env.VITE_API_URL,
  GOOGLE_CLIENT_ID:
    ((window as any)._env_?.VITE_GOOGLE_CLIENT_ID as string) ||
    import.meta.env.VITE_GOOGLE_CLIENT_ID,
  GOOGLE_SCOPE: googleScope,
};
