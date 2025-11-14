<template>
  <div v-if="speakerWithParticipation" class="flex flex-col lg:flex-row gap-6">
    <!-- Speaker information section -->
    <div class="space-y-6 w-full lg:w-96 lg:flex-shrink-0">
      <!-- Speaker Card -->
      <SpeakerCard
        :speaker="speakerWithParticipation"
        @updated="handleSpeakerUpdated"
      />

      <!-- Speaker Contact -->
      <ContactCard
        v-if="speakerWithParticipation.contactObject"
        :contact="speakerWithParticipation.contactObject"
        :contact-name="speakerWithParticipation.name"
        can-edit
        @updated="handleContactUpdated"
      />
    </div>

    <!-- Communications section -->
    <div class="flex-1 min-w-0">
      <ParticipationsCard
        v-if="speakerWithParticipation?.participations"
        :participations="speakerWithParticipation.participations"
        :entity-id="speakerId as string"
        entity-type="speaker"
        class="mb-5"
      />

      <SpeakerCommunications :speaker="speakerWithParticipation" />

      <!-- Audit logs (admin/coordinator) -->
      <div v-if="canViewLogs" class="mt-6 bg-card p-4 rounded-md">
        <h3 class="text-lg font-medium mb-2">Logs</h3>

        <div v-if="speakerLogsLoading" class="text-muted-foreground">
          Loading logs...
        </div>

        <div v-else>
          <div
            v-if="speakerLogs && speakerLogs.length === 0"
            class="text-muted-foreground"
          >
            No logs for this speaker.
          </div>

          <div v-else>
            <div v-for="log in speakerLogs" :key="log.id" class="log-entry">
              <div class="text-sm text-muted-foreground">
                {{ new Date(log.date).toLocaleString() }}
              </div>
              <div class="font-medium">
                {{ formatLogMessage(log) }}
              </div>
              <div class="text-sm text-muted-foreground">
                Actor: {{ getActorName(log.actor) }}
              </div>
              <div
                v-if="log.data && Object.keys(log.data).length"
                class="text-xs mt-1"
              >
                <pre class="whitespace-pre-wrap">{{
                  formatLogDetails(log)
                }}</pre>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { getSpeakerById } from "@/api/speakers";
import SpeakerCard from "@/components/cards/SpeakerCard.vue";
import ContactCard from "@/components/ContactCard.vue";
import ParticipationsCard from "@/components/ParticipationsCard.vue";
import type {
  SpeakerWithContactObject,
  SpeakerWithParticipation,
} from "@/dto/speakers";
import { withCurrentParticipation } from "@/lib/utils";
import { useEventStore } from "@/stores/event";

import { useQuery, useQueryCache } from "@pinia/colada";
import { computed } from "vue";
import { useRoute } from "vue-router";
import SpeakerCommunications from "@/components/speakers/SpeakerCommunications.vue";
import { useAuthStore } from "@/stores/auth";
import { getLogsBySpeaker } from "@/api/logs";
import { getAllMembers } from "@/api/members";
import type { Log } from "@/dto/logs";
import type { Member } from "@/dto/members";

const route = useRoute();
const queryCache = useQueryCache();

const speakerId = route.params.speakerId;
const { data: speaker } = useQuery({
  key: () => ["speaker", speakerId],
  query: () => getSpeakerById(speakerId as string),
});

const handleSpeakerUpdated = () => {
  // Invalidate the speaker query to refresh the data
  queryCache.invalidateQueries({ key: ["speaker", speakerId] });
};

const eventStore = useEventStore();
const speakerWithParticipation = computed(() => {
  if (!speaker.value?.data || !eventStore.selectedEvent) return null;

  return withCurrentParticipation(
    speaker.value.data,
    eventStore.selectedEvent,
  ) as SpeakerWithParticipation & SpeakerWithContactObject;
});

// logs (admin/coordinator)
const authStore = useAuthStore();
const canViewLogs = computed(() => {
  const role = authStore.decoded?.role as string | undefined;
  return role === "ADMIN" || role === "COORDINATOR";
});

const { data: speakerLogs, isLoading: speakerLogsLoading } = useQuery({
  key: () => [
    "speaker-logs",
    speakerId,
    eventStore.selectedEvent?.id ?? "no-event",
  ],
  query: () => {
    const params: Record<string, string | number> = {};
    if (eventStore.selectedEvent) params.event = eventStore.selectedEvent.id;
    return getLogsBySpeaker(speakerId as string, params).then((r) => r.data);
  },
  enabled: () => canViewLogs.value && !!speakerId && !!eventStore.selectedEvent,
});

// fetch members to resolve actor ids
const { data: membersData } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers(),
});

const membersById = computed(() => {
  const map = new Map<string, Member>();
  if (!membersData.value?.data) return map;
  for (const m of membersData.value.data) map.set(m.id, m as Member);
  return map;
});

const getActorName = (actorId?: string | null) => {
  if (!actorId) return "system";
  const m = membersById.value.get(actorId);
  return m?.name || actorId;
};

const formatLogMessage = (log: Log) => {
  const action: string = log.action || "";
  const data = log.data ?? {};

  switch (action) {
    case "UPDATED_PARTICIPATION_STATUS":
      if ("from" in data || "to" in data) {
        const from = String((data as Record<string, unknown>)["from"] ?? "—");
        const to = String((data as Record<string, unknown>)["to"] ?? "—");
        return `Participation status changed from ${from} to ${to}`;
      }
      return "Participation status changed";
    default:
      return `${log.action} — ${log.resource}`;
  }
};

const formatLogDetails = (log: Log) => {
  try {
    return JSON.stringify(log.data ?? {}, null, 2);
  } catch {
    return String(log.data ?? "");
  }
};

const handleContactUpdated = () => {
  // Invalidate the representatives query to refresh the data
  queryCache.invalidateQueries({
    key: ["speaker", speakerId],
  });
};
</script>

<style scoped>
.log-entry {
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  padding: 8px 0;
}
</style>
