import { googleSdkLoaded, type CallbackTypes } from "vue3-google-login";
import { generateJwt } from "@/api/auth";
import { useAuthStore } from "@/stores/auth";
import { ref } from "vue";
import { env } from "@/env";

export const useGoogleAuth = () => {
  const authStore = useAuthStore();
  const isSigningIn = ref(false);
  const error = ref<string | null>(null);

  const getTargetUserEmail = (explicitHint?: string) => {
    if (explicitHint) return explicitHint;
    const sinfoid = authStore.member?.sinfoid || authStore.decoded?.sinfoid;
    return sinfoid ? `${sinfoid}@sinfo.org` : undefined;
  };

  const signInWithGoogle = async (
    options: {
      prompt?: "" | "none" | "consent" | "select_account";
      hint?: string;
    } = {},
  ): Promise<boolean> => {
    return new Promise((resolve) => {
      isSigningIn.value = true;
      error.value = null;

      const userEmail = getTargetUserEmail(options.hint);
      const promptMode = options.prompt ?? "";

      googleSdkLoaded((google) => {
        try {
          const client = google.accounts.oauth2.initTokenClient({
            client_id: env.GOOGLE_CLIENT_ID,
            scope: env.GOOGLE_SCOPE,
            prompt: promptMode,
            hint: userEmail,
            hosted_domain: "sinfo.org",
            callback: async (response) => {
              try {
                await handleGoogleCallback(response);
                resolve(true);
              } catch (err) {
                error.value =
                  err instanceof Error ? err.message : "Authentication failed";
                resolve(false);
              } finally {
                isSigningIn.value = false;
              }
            },
            error_callback: (err) => {
              console.error("Error during Google login", err);
              error.value = "Google authentication failed";
              isSigningIn.value = false;
              resolve(false);
            },
          });

          client.requestAccessToken({
            prompt: promptMode,
            hint: userEmail,
          });
        } catch (err) {
          console.error("Failed to init token client:", err);
          isSigningIn.value = false;
          resolve(false);
        }
      });
    });
  };

  const handleGoogleCallback = async (
    response: CallbackTypes.TokenPopupResponse,
  ) => {
    try {
      if (!authStore.isAuthenticated) {
        const jwt = await generateJwt({ access_token: response.access_token });
        authStore.setToken(jwt.data.deck_token);
      }
    } catch (err) {
      console.error("Failed to generate JWT:", err);
      if (!authStore.isAuthenticated) {
        throw new Error("Failed to complete authentication");
      }
    }

    // Store Google token with expiration (expires_in is in seconds, default 3600)
    try {
      const expiresIn = response.expires_in
        ? Number(response.expires_in)
        : 3600;
      authStore.setGoogleToken(response.access_token, expiresIn);
    } catch (err) {
      console.error("Failed to store Google token:", err);
      throw new Error("Failed to store Google authentication token");
    }
  };

  /**
   * Request only Google access token without Deck JWT (for Gmail operations)
   * Use this when the user is already authenticated with Deck but Google token expired
   */
  const requestGoogleToken = async (
    options: {
      prompt?: "" | "none" | "consent" | "select_account";
      silent?: boolean;
      hint?: string;
    } = {},
  ): Promise<boolean> => {
    // If token is already present and not expired, reuse it immediately
    if (authStore.hasValidGoogleToken) {
      return true;
    }

    const userEmail = getTargetUserEmail(options.hint);

    const promptMode: "" | "none" | "consent" | "select_account" =
      options.silent ? "" : (options.prompt ?? "");

    return new Promise((resolve) => {
      isSigningIn.value = true;
      error.value = null;

      googleSdkLoaded((google) => {
        try {
          const client = google.accounts.oauth2.initTokenClient({
            client_id: env.GOOGLE_CLIENT_ID,
            scope: env.GOOGLE_SCOPE,
            prompt: promptMode,
            hint: userEmail,
            hosted_domain: "sinfo.org",
            callback: async (response) => {
              if (!response?.access_token) {
                console.warn("No Google access token received");
                error.value = "Failed to obtain Google access token";
                isSigningIn.value = false;
                resolve(false);
                return;
              }
              try {
                const expiresIn = response.expires_in
                  ? Number(response.expires_in)
                  : 3600;
                authStore.setGoogleToken(response.access_token, expiresIn);
                resolve(true);
              } catch (err) {
                error.value =
                  err instanceof Error
                    ? err.message
                    : "Failed to get Google token";
                resolve(false);
              } finally {
                isSigningIn.value = false;
              }
            },
            error_callback: (err) => {
              console.warn("Error during Google token request", err);
              error.value = "Google authentication failed";
              isSigningIn.value = false;
              resolve(false);
            },
          });

          client.requestAccessToken({
            prompt: promptMode,
            hint: userEmail,
          });
        } catch (err) {
          console.error("Failed to init token client:", err);
          isSigningIn.value = false;
          resolve(false);
        }
      });
    });
  };

  const signOut = () => {
    authStore.clearToken();
    authStore.clearGoogleToken();
  };

  return {
    isSigningIn,
    error,
    signInWithGoogle,
    requestGoogleToken,
    signOut,
  };
};
