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
import { useRoute } from "vue-router";
import Navbar from "@/components/Navbar.vue";
import { useAuthStore } from "@/stores/auth";
import { useEventStore } from "@/stores/event";
import { useAutoLinkGmail } from "@/composables/useAutoLinkGmail";
import { useToast } from "@/lib/toast";

const currentRoute = useRoute();
const authStore = useAuthStore();
const eventStore = useEventStore();
const { syncRecentGmailUpdates, warnUnlinkedContacted } = useAutoLinkGmail();
const { toast } = useToast();

const syncedEventId = ref<number | null>(null);

// Auto delta-sync recent emails on refresh if connected
watch(
  () => [eventStore.selectedEvent, authStore.isGoogleAuthenticated] as const,
  async ([event, isGoogleAuth]) => {
    if (!isGoogleAuth) {
      syncedEventId.value = null;
      return;
    }

    if (event?.id && isGoogleAuth && syncedEventId.value !== event.id) {
      syncedEventId.value = event.id;
      try {
        const results = await syncRecentGmailUpdates(event.id);
        const updatedCount = results.filter(
          (r) => r.status === "SUCCESS",
        ).length;
        if (updatedCount > 0 && currentRoute.name !== "settings") {
          const names = results
            .filter((r) => r.status === "SUCCESS")
            .slice(0, 3)
            .map((r) => r.entityName)
            .join(", ");
          const extra = updatedCount > 3 ? ` and ${updatedCount - 3} more` : "";
          toast.success({
            title: "New Emails Synced",
            description: `Updated communications for: ${names}${extra}.`,
          });
        }

        warnUnlinkedContacted(results);
      } catch (err) {
        console.warn("Delta sync on refresh failed:", err);
      }
    }
  },
  { immediate: true },
);
</script>
