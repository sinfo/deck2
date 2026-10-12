<template>
  <div v-if="speakerWithParticipation" class="flex flex-col lg:flex-row gap-6">
    <!-- Speaker information section -->
    <div class="space-y-6 w-full lg:w-96 lg:flex-shrink-0">
      <!-- Speaker Card -->
      <SpeakerCard
        :speaker="speakerWithParticipation"
        @updated="handleSpeakerUpdated"
      />

      <DirectEmailDialogTrigger
        v-if="speakerWithParticipation"
        :entity="speakerWithParticipation"
        entity-type="speaker"
        button-class="w-full"
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

    <!-- Info/Tasks section -->
    <div class="flex-1 min-w-0">
      <Tabs v-model="activeTab" default-value="info" class="w-full">
        <TabsList class="grid w-full grid-cols-2 max-w-md">
          <TabsTrigger value="info"> Info </TabsTrigger>
          <TabsTrigger value="tasks"> Tasks </TabsTrigger>
        </TabsList>

        <TabsContent value="info">
          <div class="space-y-5">
            <ParticipationsCard
              v-if="speakerWithParticipation?.participations"
              :participations="speakerWithParticipation.participations"
              :entity-id="speakerId as string"
              entity-type="speaker"
            />

            <SpeakerCommunications :speaker="speakerWithParticipation" />
          </div>
        </TabsContent>

        <TabsContent value="tasks">
          <Tasks
            entity-type="speaker"
            :entity-id="speakerWithParticipation.id"
            :participation="speakerWithParticipation.participation"
            :contact="speakerWithParticipation.contactObject"
            :speaker-imgs="speakerWithParticipation.imgs"
          />
        </TabsContent>
      </Tabs>
    </div>
  </div>
</template>

<script setup lang="ts">
import { getSpeakerById } from "@/api/speakers";
import SpeakerCard from "@/components/cards/SpeakerCard.vue";
import ContactCard from "@/components/ContactCard.vue";
import ParticipationsCard from "@/components/ParticipationsCard.vue";
import DirectEmailDialogTrigger from "@/components/DirectEmailDialogTrigger.vue";
import Tasks from "@/components/tasks/Tasks.vue";
import type {
  SpeakerWithContactObject,
  SpeakerWithParticipation,
} from "@/dto/speakers";
import { withCurrentParticipation } from "@/lib/utils";
import { useEventStore } from "@/stores/event";

import { useQuery, useQueryCache } from "@pinia/colada";
import { computed, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import SpeakerCommunications from "@/components/speakers/SpeakerCommunications.vue";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";

const route = useRoute();
const router = useRouter();
const queryCache = useQueryCache();

const validTabs = ["info", "tasks"] as const;
type TabValue = (typeof validTabs)[number];
const activeTab = ref<TabValue>(
  validTabs.includes(route.query.tab as TabValue)
    ? (route.query.tab as TabValue)
    : "info",
);
watch(activeTab, (tab) => {
  router.replace({ query: { ...route.query, tab } });
});

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

const handleContactUpdated = () => {
  // Invalidate the representatives query to refresh the data
  queryCache.invalidateQueries({
    key: ["speaker", speakerId],
  });
};
</script>
