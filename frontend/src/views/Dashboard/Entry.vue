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
import { useToast } from "@/lib/toast";

const authStore = useAuthStore();
const eventStore = useEventStore();
const { autoLinkEventEntities } = useAutoLinkGmail();
const { toast } = useToast();

const syncedEventId = ref<number | null>(null);

// Automatically sync Gmail on Deck load/refresh and event switch if connected
watch(
  () => [eventStore.selectedEvent, authStore.isGoogleAuthenticated] as const,
  async ([event, isGoogleAuth]) => {
    if (event?.id && isGoogleAuth && syncedEventId.value !== event.id) {
      syncedEventId.value = event.id;
      try {
        const results = await autoLinkEventEntities(event.id, {
          onlyMyResponsibilities: true,
        });
        const notFoundContacted = results.filter(
          (r) =>
            r.status === "NOT_FOUND" &&
            r.participationStatus &&
            [
              "CONTACTED",
              "IN_CONVERSATIONS",
              "ACCEPTED",
              "REJECTED",
              "GIVEN_UP",
            ].includes(r.participationStatus),
        );
        if (notFoundContacted.length > 0) {
          const names = notFoundContacted
            .slice(0, 3)
            .map((r) => r.entityName)
            .join(", ");
          const extra =
            notFoundContacted.length > 3
              ? ` and ${notFoundContacted.length - 3} more`
              : "";
          toast.warning({
            title: "Gmail Threads Not Found",
            description: `Could not find Gmail threads for ${notFoundContacted.length} contacted entity/entities: ${names}${extra}.`,
          });
        }
      } catch (err) {
        console.warn("Auto-sync on refresh failed:", err);
      }
    }
  },
  { immediate: true },
);
</script>
