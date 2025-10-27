<template>
  <WorkflowCard
    :key="speaker.id"
    :image="
      speaker.imgs?.internal || speaker.imgs?.speaker || speaker.imgs?.company
    "
    :title="speaker.name"
    :current-status="speaker.participation?.status"
    :to="{ name: 'speaker', params: { speakerId: speaker.id } }"
    @status-change="updateSpeakerStatus(speaker, $event)"
  />
</template>

<script setup lang="ts">
import WorkflowCard from "./WorkflowCard.vue";
import type { SpeakerWithParticipation } from "@/dto/speakers";
import { useSpeakerParticipationStepMutation } from "@/mutations/speakers";

defineProps<{
  speaker: SpeakerWithParticipation;
}>();

const speakerParticipationStepMutation = useSpeakerParticipationStepMutation();
const updateSpeakerStatus = (
  speaker: SpeakerWithParticipation,
  step: number,
) => {
  speakerParticipationStepMutation.speakerId.value = speaker.id;
  speakerParticipationStepMutation.step.value = step;
  speakerParticipationStepMutation.mutate();
};
</script>
