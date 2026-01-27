<template>
  <Communications
    :entity="speaker"
    entity-type="speaker"
    description="Communication history with speaker"
    :participations="speaker.participations"
    can-send-messages
    :templates="templates"
    :fetch-communications="getSpeakerCommunications"
    :post-thread-mutation="postThreadMutation"
  />
</template>

<script setup lang="ts">
import { getSpeakerCommunications } from "@/api/speakers";
import type { SpeakerWithContactObject } from "@/dto/speakers";
import { useEventStore } from "@/stores/event";
import { usePostSpeakerThreadMutation } from "@/mutations/speakers";
import Communications from "../Communications.vue";
import { speakerTemplates, createEmailVariable } from "@/lib/templates";
import { computed } from "vue";
import { useAuthStore } from "@/stores/auth";

const props = defineProps<{
  speaker: SpeakerWithContactObject;
}>();

const eventStore = useEventStore();
const authStore = useAuthStore();

// Setup mutation for posting threads (currently disabled for speakers)
const postThreadMutation = usePostSpeakerThreadMutation();
postThreadMutation.speakerId.value = props.speaker.id;

const templates = computed(() =>
  speakerTemplates.map((it) => ({
    template: it,
    variables: createSpeakerTemplateVariables(),
  })),
);

const createSpeakerTemplateVariables = () => {
  const endDate = new Date(eventStore.selectedEvent?.end || 0);
  const memberGender = authStore.member!.contactObject.gender;
  const speakerGender = props.speaker.contactObject.gender;

  return [
    createEmailVariable.memberArticle(memberGender),
    createEmailVariable.memberSuffix(memberGender),
    createEmailVariable.member(authStore.member!),
    createEmailVariable.speakerArticle(speakerGender),
    createEmailVariable.speakerSuffix(speakerGender),
    createEmailVariable.speaker(props.speaker),
    createEmailVariable.edition(eventStore.selectedEvent?.id || 0),
    createEmailVariable.editionOrdinal(eventStore.selectedEvent?.id || 0),
    createEmailVariable.eventStartDay(
      new Date(eventStore.selectedEvent?.begin || 0),
    ),
    createEmailVariable.eventEndDay(endDate),
    createEmailVariable.eventEndMonth(endDate),
    createEmailVariable.eventEndYear(endDate),
  ];
};
</script>
