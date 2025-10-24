import { googleSdkLoaded, type CallbackTypes } from "vue3-google-login";
import { generateJwt } from "@/api/auth";
import { useAuthStore } from "@/stores/auth";
import { ref } from "vue";
import { env } from "@/env";

export const useGoogleAuth = () => {
  const authStore = useAuthStore();
  const isSigningIn = ref(false);
  const error = ref<string | null>(null);

  const signInWithGoogle = async (): Promise<boolean> => {
    return new Promise((resolve) => {
      isSigningIn.value = true;
      error.value = null;

      googleSdkLoaded((google) => {
        google.accounts.oauth2
          .initTokenClient({
            client_id: env.GOOGLE_CLIENT_ID,
            scope: env.GOOGLE_SCOPE,
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
          })
          .requestAccessToken();
      });
    });
  };

  const handleGoogleCallback = async (
    response: CallbackTypes.TokenPopupResponse,
  ) => {
    try {
      const jwt = await generateJwt({ access_token: response.access_token });
      authStore.setToken(jwt.data.deck_token);
      authStore.googleAccessToken = response.access_token;
    } catch (err) {
      console.error("Failed to generate JWT:", err);
      throw new Error("Failed to complete authentication");
    }
  };

  const signOut = () => {
    authStore.clearToken();
    authStore.googleAccessToken = null;
  };

  return {
    isSigningIn,
    error,
    signInWithGoogle,
    signOut,
  };
};
