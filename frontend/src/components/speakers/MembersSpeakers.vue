<template>
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold">Speakers</h1>
    <CreateSpeakerDialogTrigger />
  </div>

  <div
    class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
    v-if="!membersSorted.length && speakersLoading"
  >
    <Skeleton v-for="i in 21" :key="i" class="h-[260px] w-full rounded-lg" />
  </div>

  <div v-else-if="!speakers.length && !speakersLoading" class="text-center">
    <p>No speakers found</p>
  </div>

  <DynamicScroller
    v-else
    :items="membersSorted"
    class="h-100"
    :min-item-size="1"
  >
    <template v-slot="{ item }">
      <MemberWithAvatar :member="item" with-separator />

      <div
        class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
      >
        <SpeakerWorkflowCard
          v-for="speaker in participations?.get(item.id) || []"
          :key="speaker.id"
          :speaker="speaker"
        />
      </div>
    </template>
  </DynamicScroller>
</template>

<script setup lang="ts">
import { computed } from "vue";
import type { Member } from "@/dto/members";
import MemberWithAvatar from "@/components/members/MemberWithAvatar.vue";
import { DynamicScroller } from "vue-virtual-scroller";
import type { Speaker, SpeakerWithParticipation } from "@/dto/speakers";
import { useInsertionSort, useSortByParticipationStatus } from "@/lib/utils";
import { Skeleton } from "../ui/skeleton";
import SpeakerWorkflowCard from "../cards/SpeakerWorkflowCard.vue";
import CreateSpeakerDialogTrigger from "./CreateSpeakerDialogTrigger.vue";

const props = defineProps<{
  speakers: Speaker[];
  speakersLoading?: boolean;
  members: Member[];
  eventId: number;
}>();

// TODO shift me to top
const membersSorted = computed(() => {
  return props.members?.sort((a, b) => a.name.localeCompare(b.name));
});

const membersMap = computed(() => {
  return props.members?.reduce(
    (acc, member) => {
      acc[member.id] = member;
      return acc;
    },
    {} as Record<string, Member>,
  );
});

const participations = computed(() =>
  props.speakers?.reduce((acc, speaker) => {
    const currParticipation = speaker.participations.find(
      (participation) => participation.event === props.eventId,
    );

    if (currParticipation && currParticipation.member in membersMap.value!) {
      const member = membersMap.value?.[currParticipation.member];
      if (!member) return acc; // Skip if member not found

      if (!acc.has(member.id)) acc.set(member.id, []);

      useInsertionSort(
        acc.get(member.id)!,
        {
          ...speaker,
          participation: currParticipation,
        },
        (a, b) =>
          useSortByParticipationStatus(a.participation, b.participation),
      );
    }

    return acc;
  }, new Map<string, SpeakerWithParticipation[]>()),
);
</script>
