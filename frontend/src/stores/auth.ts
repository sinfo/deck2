import { getMe } from "@/api/members";
import type { JWTAuth, MemberWithContact } from "@/dto/members";
import { defineStore } from "pinia";
import { computed, ref, watch } from "vue";

const parseJwt = (token: string): JWTAuth | null => {
  try {
    const base64Url = token.split(".")[1];
    if (!base64Url) return null;
    const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
    const jsonPayload = decodeURIComponent(
      window
        .atob(base64)
        .split("")
        .map((c) => "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2))
        .join(""),
    );

    return JSON.parse(jsonPayload);
  } catch (err) {
    console.error("Failed to parse JWT:", err);
    return null;
  }
};

const GOOGLE_STORAGE_KEYS = {
  CONNECTED: "isGoogleConnected",
  ACCESS_TOKEN: "googleAccessToken",
  TOKEN_EXPIRY: "googleAccessTokenExpiry",
  CONNECTED_EMAIL: "googleConnectedEmail",
} as const;

export const useAuthStore = defineStore("auth", () => {
  const token = ref<string | null>(localStorage.getItem("authToken"));
  const isInitializing = ref(true);
  const decoded = computed<JWTAuth>(() =>
    token.value
      ? (parseJwt(token.value) as JWTAuth)
      : (null as unknown as JWTAuth),
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

  // Active SINFO member ID (from loaded member or JWT claims)
  const memberSinfoid = computed<string | null>(() => {
    const raw = member.value?.sinfoid || decoded.value?.sinfoid;
    return raw ? raw.toLowerCase().trim() : null;
  });

  // SINFO email associated with current user
  const sinfoEmail = computed<string | null>(() => {
    const sinfoid = memberSinfoid.value;
    return sinfoid ? `${sinfoid}@sinfo.org` : null;
  });

  // Helpers to scope localStorage keys per member to prevent cross-account data leakage
  const getScopedKey = (key: string, sinfoid?: string | null) => {
    const id = (sinfoid || memberSinfoid.value)?.toLowerCase().trim();
    return id ? `${key}:${id}` : null;
  };

  const migrateLegacyGoogleKeys = (sinfoid: string) => {
    const legacyConnected = localStorage.getItem(GOOGLE_STORAGE_KEYS.CONNECTED);
    const legacyEmail = localStorage.getItem(
      GOOGLE_STORAGE_KEYS.CONNECTED_EMAIL,
    );
    const legacyToken = localStorage.getItem(GOOGLE_STORAGE_KEYS.ACCESS_TOKEN);
    const legacyExpiry = localStorage.getItem(GOOGLE_STORAGE_KEYS.TOKEN_EXPIRY);

    if (legacyConnected !== null) {
      const scopedConnKey = getScopedKey(
        GOOGLE_STORAGE_KEYS.CONNECTED,
        sinfoid,
      );
      if (scopedConnKey && localStorage.getItem(scopedConnKey) === null) {
        const memberEmail = `${sinfoid.toLowerCase()}@sinfo.org`;
        if (!legacyEmail || legacyEmail.toLowerCase().trim() === memberEmail) {
          localStorage.setItem(scopedConnKey, legacyConnected);
          if (legacyEmail) {
            const scopedEmailKey = getScopedKey(
              GOOGLE_STORAGE_KEYS.CONNECTED_EMAIL,
              sinfoid,
            );
            if (scopedEmailKey)
              localStorage.setItem(scopedEmailKey, legacyEmail);
          }
          if (legacyToken) {
            const scopedTokenKey = getScopedKey(
              GOOGLE_STORAGE_KEYS.ACCESS_TOKEN,
              sinfoid,
            );
            if (scopedTokenKey)
              localStorage.setItem(scopedTokenKey, legacyToken);
          }
          if (legacyExpiry) {
            const scopedExpiryKey = getScopedKey(
              GOOGLE_STORAGE_KEYS.TOKEN_EXPIRY,
              sinfoid,
            );
            if (scopedExpiryKey)
              localStorage.setItem(scopedExpiryKey, legacyExpiry);
          }
        }
      }
      // Remove legacy unscoped keys to prevent inheritance by other members
      localStorage.removeItem(GOOGLE_STORAGE_KEYS.CONNECTED);
      localStorage.removeItem(GOOGLE_STORAGE_KEYS.CONNECTED_EMAIL);
      localStorage.removeItem(GOOGLE_STORAGE_KEYS.ACCESS_TOKEN);
      localStorage.removeItem(GOOGLE_STORAGE_KEYS.TOKEN_EXPIRY);
    }
  };

  // Google Auth integration state scoped by member
  const isGoogleConnected = ref<boolean>(false);
  const connectedGoogleEmail = ref<string | null>(null);
  const googleAccessToken = ref<string | null>(null);
  const googleAccessTokenExpiry = ref<number | null>(null);

  const loadGoogleStateForMember = (sinfoid: string | null) => {
    if (!sinfoid) {
      isGoogleConnected.value = false;
      connectedGoogleEmail.value = null;
      googleAccessToken.value = null;
      googleAccessTokenExpiry.value = null;
      return;
    }

    migrateLegacyGoogleKeys(sinfoid);

    const connKey = getScopedKey(GOOGLE_STORAGE_KEYS.CONNECTED, sinfoid);
    const emailKey = getScopedKey(GOOGLE_STORAGE_KEYS.CONNECTED_EMAIL, sinfoid);
    const tokenKey = getScopedKey(GOOGLE_STORAGE_KEYS.ACCESS_TOKEN, sinfoid);
    const expiryKey = getScopedKey(GOOGLE_STORAGE_KEYS.TOKEN_EXPIRY, sinfoid);

    isGoogleConnected.value = connKey
      ? localStorage.getItem(connKey) === "true"
      : false;
    connectedGoogleEmail.value = emailKey
      ? localStorage.getItem(emailKey)
      : null;
    googleAccessToken.value = tokenKey ? localStorage.getItem(tokenKey) : null;
    const expiryVal = expiryKey ? localStorage.getItem(expiryKey) : null;
    googleAccessTokenExpiry.value = expiryVal ? Number(expiryVal) : null;
  };

  watch(
    memberSinfoid,
    (newSinfoId) => {
      loadGoogleStateForMember(newSinfoId);
    },
    { immediate: true },
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
  const connectGoogle = (emailOrSinfoid?: string | null) => {
    isGoogleConnected.value = true;
    const targetSinfoid =
      memberSinfoid.value ||
      (emailOrSinfoid
        ? emailOrSinfoid.includes("@")
          ? emailOrSinfoid.split("@")[0]
          : emailOrSinfoid
        : null);
    const key = getScopedKey(GOOGLE_STORAGE_KEYS.CONNECTED, targetSinfoid);
    if (key) {
      localStorage.setItem(key, "true");
    }
  };

  // Set Google token with expiration (expiresIn is in seconds)
  const setGoogleToken = (
    token: string,
    expiresIn: number = 3600,
    email?: string,
  ) => {
    googleAccessToken.value = token;
    // Calculate expiry timestamp (subtract 60 seconds for safety margin)
    const expiryTime = Date.now() + (expiresIn - 60) * 1000;
    googleAccessTokenExpiry.value = expiryTime;

    const targetSinfoid =
      memberSinfoid.value || (email ? email.split("@")[0] : null);

    const tokenKey = getScopedKey(
      GOOGLE_STORAGE_KEYS.ACCESS_TOKEN,
      targetSinfoid,
    );
    const expiryKey = getScopedKey(
      GOOGLE_STORAGE_KEYS.TOKEN_EXPIRY,
      targetSinfoid,
    );
    if (tokenKey) localStorage.setItem(tokenKey, token);
    if (expiryKey) localStorage.setItem(expiryKey, String(expiryTime));

    if (email) {
      connectedGoogleEmail.value = email;
      const emailKey = getScopedKey(
        GOOGLE_STORAGE_KEYS.CONNECTED_EMAIL,
        targetSinfoid,
      );
      if (emailKey) localStorage.setItem(emailKey, email);
    }
  };

  // Clear expired/invalid token in memory/storage (does NOT disconnect the user!)
  const clearGoogleToken = () => {
    googleAccessToken.value = null;
    googleAccessTokenExpiry.value = null;
    const tokenKey = getScopedKey(GOOGLE_STORAGE_KEYS.ACCESS_TOKEN);
    const expiryKey = getScopedKey(GOOGLE_STORAGE_KEYS.TOKEN_EXPIRY);
    if (tokenKey) localStorage.removeItem(tokenKey);
    if (expiryKey) localStorage.removeItem(expiryKey);
  };

  // Explicit manual disconnection by the user
  const disconnectGoogle = () => {
    isGoogleConnected.value = false;
    connectedGoogleEmail.value = null;
    const connKey = getScopedKey(GOOGLE_STORAGE_KEYS.CONNECTED);
    const emailKey = getScopedKey(GOOGLE_STORAGE_KEYS.CONNECTED_EMAIL);
    if (connKey) localStorage.removeItem(connKey);
    if (emailKey) localStorage.removeItem(emailKey);
    clearGoogleToken();
  };

  const setToken = (newToken: string) => {
    token.value = newToken;
    localStorage.setItem("authToken", newToken);
  };

  const clearToken = () => {
    clearGoogleToken();
    token.value = null;
    localStorage.removeItem("authToken");
    loadGoogleStateForMember(null);
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

  return {
    token,
    decoded,
    member,
    memberSinfoid,
    sinfoEmail,
    isInitializing,
    isAuthenticated,
    setToken,
    clearToken,
    initialize,

    isGoogleConnected,
    connectedGoogleEmail,
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
