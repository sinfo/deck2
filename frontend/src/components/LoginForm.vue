<script setup lang="ts">
import { type HTMLAttributes } from "vue";
import { googleSdkLoaded, type CallbackTypes } from "vue3-google-login";
import { cn } from "@/lib/utils";
import Button from "./ui/button/Button.vue";
import { generateJwt } from "@/api/auth";
import { useAuthStore } from "@/stores/auth";
import GoogleIcon from "@/assets/google-icon.svg";
import { useRoute, useRouter } from "vue-router";

const props = defineProps<{
  class?: HTMLAttributes["class"];
}>();

const login = () => {
  googleSdkLoaded((google) => {
    google.accounts.oauth2
      .initTokenClient({
        client_id: import.meta.env.VITE_GOOGLE_CLIENT_ID,
        scope: import.meta.env.VITE_GOOGLE_SCOPE,
        callback: (response) => {
          callback(response);
        },
        error_callback: (error) => {
          console.error("Error during Google login", error);
        },
      })
      .requestAccessToken();
  });
};

const router = useRouter();
const route = useRoute();
const to = route.query.to as string;

const authStore = useAuthStore();
const callback = async (response: CallbackTypes.TokenPopupResponse) => {
  const jwt = await generateJwt({ access_token: response.access_token });
  authStore.setToken(jwt.data.deck_token);
  authStore.googleAccessToken = response.access_token;

  if (to) router.push(to);
  else router.push({ name: "dashboard" });
};
</script>

<template>
  <form :class="cn('flex flex-col gap-2', props.class)">
    <div class="flex flex-col items-center gap-2 text-center">
      <h1 class="text-2xl font-bold">SINFO Deck</h1>
      <p class="text-muted-foreground text-sm text-balance">
        Internal Management Tool
      </p>
    </div>
    <div class="flex flex-1 items-center justify-center flex-col gap-4">
      <Button @click.prevent="login" class="flex items-center gap-2">
        <img :src="GoogleIcon" alt="Google" class="w-4 h-4" />
        Login with Google
      </Button>
      <!-- <GoogleLogin :callback="callback" /> -->
    </div>
  </form>
</template>
