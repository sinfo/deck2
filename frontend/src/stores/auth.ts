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

  // Google Auth access token
  const googleAccessToken = ref<string | null>();

  return {
    token,
    decoded,
    member,
    isInitializing,
    isAuthenticated,
    setToken,
    clearToken,
    initialize,

    googleAccessToken,
  };
});
