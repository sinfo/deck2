<template>
  <!-- 
   This is not really used because the check is local (checking if jwt is valid)
    Keeping this for potential future use
  -->
  <!-- <AuthLoader v-if="authStore.isInitializing" /> -->
  <router-view />

  <PiniaColadaDevtools />
</template>

<script lang="ts" setup>
import { PiniaColadaDevtools } from "@pinia/colada-devtools";
import { useAuthStore } from "@/stores/auth";

const authStore = useAuthStore();

// Initialize authentication on app start
authStore.initialize();
</script>
