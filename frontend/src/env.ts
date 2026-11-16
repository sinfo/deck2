/* eslint-disable @typescript-eslint/no-explicit-any */
const configuredGoogleScope =
  ((window as any)._env_?.VITE_GOOGLE_SCOPE as string) ||
  import.meta.env.VITE_GOOGLE_SCOPE ||
  "";

export const env = {
  API_URL:
    ((window as any)._env_?.VITE_API_URL as string) ||
    import.meta.env.VITE_API_URL,

  GOOGLE_CLIENT_ID:
    ((window as any)._env_?.VITE_GOOGLE_CLIENT_ID as string) ||
    import.meta.env.VITE_GOOGLE_CLIENT_ID,

  // Gmail thread lookup needs read access even if deployment scopes omit it.
  GOOGLE_SCOPE: [
    ...new Set([
      ...configuredGoogleScope.split(/\s+/).filter(Boolean),
      "https://www.googleapis.com/auth/gmail.readonly",
    ]),
  ].join(" "),
};
