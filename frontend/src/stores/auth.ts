import { getMe } from "@/api/members";
import type { JWTAuth, MemberWithContact } from "@/dto/members";
import { defineStore } from "pinia";
import { computed, ref, watch } from "vue";

const parseJwt = (token: string) => {
  const base64Url = token.split(".")[1];
  const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
  const jsonPayload = decodeURIComponent(
    window
      .atob(base64)
      .split("")
      .map((c) => "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2))
      .join(""),
  );

  return JSON.parse(jsonPayload);
};

export const useAuthStore = defineStore("auth", () => {
  const token = ref<string | null>(localStorage.getItem("authToken"));
  const isInitializing = ref(true);
  const decoded = computed<JWTAuth>(() =>
    token.value ? parseJwt(token.value) : null,
  );

  const isAuthenticated = computed(() => {
    if (!token.value) return false;
    const expires = decoded.value?.exp ? decoded.value.exp * 1000 : null;
    if (expires && expires < Date.now()) {
      return false;
    }
    return true;
  });

  const member = ref<MemberWithContact | null>(null);
  watch(
    isAuthenticated,
    async (newValue) => {
      if (newValue) {
        member.value = (await getMe()).data;
      } else {
        member.value = null;
      }
    },
    { immediate: true },
  );

  const setToken = (newToken: string) => {
    token.value = newToken;
    localStorage.setItem("authToken", newToken);
  };

  const clearToken = () => {
    token.value = null;
    localStorage.removeItem("authToken");
  };

  const initialize = async () => {
    // Check if token exists and is valid
    if (token.value) {
      const expires = decoded.value?.exp ? decoded.value.exp * 1000 : null;
      if (expires && expires < Date.now()) {
        clearToken();
      }
    }
    isInitializing.value = false;
  };

  // Google Auth integration state
  // Once connected, stays connected permanently until user manually clicks Disconnect!
  const isGoogleConnected = ref<boolean>(
    localStorage.getItem("isGoogleConnected") === "true",
  );

  const googleAccessToken = ref<string | null>(
    localStorage.getItem("googleAccessToken"),
  );
  const googleAccessTokenExpiry = ref<number | null>(
    localStorage.getItem("googleAccessTokenExpiry")
      ? Number(localStorage.getItem("googleAccessTokenExpiry"))
      : null,
  );

  // For components checking if Gmail is connected (Settings, Badges, etc.)
  const isGoogleAuthenticated = computed(() => isGoogleConnected.value);

  // For checking if the access token is currently valid and unexpired
  const hasValidGoogleToken = computed(() => {
    if (!googleAccessToken.value) return false;
    if (
      googleAccessTokenExpiry.value &&
      googleAccessTokenExpiry.value < Date.now()
    ) {
      return false;
    }
    return true;
  });

  // Explicit manual connection by the user
  const connectGoogle = () => {
    isGoogleConnected.value = true;
    localStorage.setItem("isGoogleConnected", "true");
  };

  // Set Google token with expiration (expiresIn is in seconds)
  const setGoogleToken = (token: string, expiresIn: number = 3600) => {
    googleAccessToken.value = token;
    // Calculate expiry timestamp (subtract 60 seconds for safety margin)
    const expiryTime = Date.now() + (expiresIn - 60) * 1000;
    googleAccessTokenExpiry.value = expiryTime;

    localStorage.setItem("googleAccessToken", token);
    localStorage.setItem("googleAccessTokenExpiry", String(expiryTime));
  };

  // Clear expired/invalid token in memory/storage (does NOT disconnect the user!)
  const clearGoogleToken = () => {
    googleAccessToken.value = null;
    googleAccessTokenExpiry.value = null;
    localStorage.removeItem("googleAccessToken");
    localStorage.removeItem("googleAccessTokenExpiry");
  };

  // Explicit manual disconnection by the user
  const disconnectGoogle = () => {
    isGoogleConnected.value = false;
    localStorage.removeItem("isGoogleConnected");
    clearGoogleToken();
  };

  return {
    token,
    decoded,
    member,
    isInitializing,
    isAuthenticated,
    setToken,
    clearToken,
    initialize,

    isGoogleConnected,
    googleAccessToken,
    googleAccessTokenExpiry,
    isGoogleAuthenticated,
    hasValidGoogleToken,
    connectGoogle,
    setGoogleToken,
    clearGoogleToken,
    disconnectGoogle,
  };
});
