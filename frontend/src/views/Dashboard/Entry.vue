<template>
  <Navbar />

  <div class="container mx-auto p-4 pt-20">
    <router-view v-slot="{ Component, route }">
      <keep-alive :max="5">
        <component :is="Component" :key="route.path" />
      </keep-alive>
    </router-view>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import Navbar from "@/components/Navbar.vue";
import { useAuthStore } from "@/stores/auth";
import { useEventStore } from "@/stores/event";
import { useAutoLinkGmail } from "@/composables/useAutoLinkGmail";

const authStore = useAuthStore();
const eventStore = useEventStore();
const { autoLinkEventEntities } = useAutoLinkGmail();

const syncedEventId = ref<number | null>(null);

// Automatically sync Gmail on Deck load/refresh and event switch if connected
watch(
  () => [eventStore.selectedEvent, authStore.isGoogleAuthenticated] as const,
  async ([event, isGoogleAuth]) => {
    if (event?.id && isGoogleAuth && syncedEventId.value !== event.id) {
      syncedEventId.value = event.id;
      try {
        await autoLinkEventEntities(event.id, { onlyMyResponsibilities: true });
      } catch (err) {
        console.warn("Auto-sync on refresh failed:", err);
      }
    }
  },
  { immediate: true },
);
</script>
