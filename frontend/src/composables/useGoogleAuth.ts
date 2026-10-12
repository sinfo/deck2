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
    return explicitHint || authStore.sinfoEmail || undefined;
  };

  const executeTokenRequest = (options: {
    promptMode: "" | "none" | "consent" | "select_account";
    userEmail?: string;
    onToken: (response: CallbackTypes.TokenPopupResponse) => Promise<void>;
  }): Promise<boolean> => {
    return new Promise((resolve) => {
      isSigningIn.value = true;
      error.value = null;

      googleSdkLoaded((google) => {
        try {
          const client = google.accounts.oauth2.initTokenClient({
            client_id: env.GOOGLE_CLIENT_ID,
            scope: env.GOOGLE_SCOPE,
            prompt: options.promptMode,
            hint: options.userEmail,
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
                await options.onToken(response);
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
              console.warn("Error during Google token request", err);
              error.value = "Google authentication failed";
              isSigningIn.value = false;
              resolve(false);
            },
          });

          client.requestAccessToken({
            prompt: options.promptMode,
            hint: options.userEmail,
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

  const signInWithGoogle = async (
    options: {
      prompt?: "" | "none" | "consent" | "select_account";
      hint?: string;
    } = {},
  ): Promise<boolean> => {
    const userEmail = getTargetUserEmail(options.hint);
    const promptMode = options.prompt ?? "";

    return executeTokenRequest({
      promptMode,
      userEmail,
      onToken: handleGoogleCallback,
    });
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
    if (authStore.hasValidGoogleToken) {
      return true;
    }

    const userEmail = getTargetUserEmail(options.hint);
    const promptMode: "" | "none" | "consent" | "select_account" =
      options.silent ? "" : (options.prompt ?? "");

    return executeTokenRequest({
      promptMode,
      userEmail,
      onToken: async (response) => {
        const expiresIn = response.expires_in
          ? Number(response.expires_in)
          : 3600;
        authStore.setGoogleToken(response.access_token, expiresIn);
      },
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
