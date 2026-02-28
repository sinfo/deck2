<template>
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold">Speakers</h1>
    <CreateSpeakerDialogTrigger />
  </div>

  <div class="flex flex-wrap gap-3 mb-4 items-center">
    <ParticipationFilters v-model:selected="selectedStatus" />
    <Select v-model="selectedTeamId">
      <SelectTrigger class="w-52">
        <SelectValue placeholder="All teams" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="all">All teams</SelectItem>
        <SelectItem
          v-for="team in coordinationTeams"
          :key="team.id"
          :value="team.id"
        >
          {{ team.name }}
        </SelectItem>
      </SelectContent>
    </Select>
  </div>

  <div
    v-if="!membersSorted.length && speakersLoading"
    class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
  >
    <Skeleton v-for="i in 21" :key="i" class="h-[260px] w-full rounded-lg" />
  </div>

  <div
    v-else-if="!membersWithParticipations.length && !speakersLoading"
    class="text-center"
  >
    <p>No speakers found</p>
  </div>

  <div v-else>
    <div
      v-for="item in membersWithParticipations"
      :key="item.id"
      class="w-full border-b border-muted-foreground/10 pb-4 mb-4"
    >
      <div class="flex items-center justify-between w-full py-2">
        <RouterLink
          :to="{ name: 'member', params: { memberId: item.id } }"
          class="flex items-center gap-3 no-underline"
        >
          <MemberWithAvatar :member="item" with-separator />
        </RouterLink>
        <button
          type="button"
          class="p-2 rounded-md hover:bg-slate-100"
          :aria-expanded="isExpanded(item.id)"
          @click="toggleExpanded(item.id)"
        >
          <ChevronDown
            :class="[
              'transition-transform',
              isExpanded(item.id) ? 'rotate-180' : '',
            ]"
            class="w-5 h-5 text-muted-foreground"
          />
        </button>
      </div>

      <div
        v-if="isExpanded(item.id)"
        class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 mt-3"
      >
        <SpeakerWorkflowCard
          v-for="speaker in participationsFiltered?.get(item.id) || []"
          :key="speaker.id"
          :speaker="speaker"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Member } from "@/dto/members";
import type { CoordinationTeam } from "@/dto/coordinationTeams";
import MemberWithAvatar from "@/components/members/MemberWithAvatar.vue";
import type { Speaker, SpeakerWithParticipation } from "@/dto/speakers";
import { useInsertionSort, useSortByParticipationStatus } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import SpeakerWorkflowCard from "../cards/SpeakerWorkflowCard.vue";
import CreateSpeakerDialogTrigger from "./CreateSpeakerDialogTrigger.vue";
import { ref, computed, type ComputedRef } from "vue";
import { ChevronDown } from "lucide-vue-next";
import { useParticipationFilter } from "@/composables/useParticipationFilter";
import type { ParticipationStatus } from "@/dto";
import ParticipationFilters from "@/components/ParticipationFilters.vue";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const props = defineProps<{
  speakers: Speaker[];
  speakersLoading?: boolean;
  members: Member[];
  eventId: number;
  coordinationTeams?: CoordinationTeam[];
}>();

// TODO shift me to top
const membersSorted = computed(() => {
  const sorted = [...props.members]?.sort((a, b) =>
    a.name.localeCompare(b.name),
  );
  if (!selectedTeamId.value || selectedTeamId.value === "all") return sorted;
  const team = props.coordinationTeams?.find(
    (t) => t.id === selectedTeamId.value,
  );
  if (!team) return sorted;
  const teamMemberSet = new Set(team.coordinatedMembers);
  return sorted.filter((m) => teamMemberSet.has(m.id));
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

// Set of member IDs visible after team filtering
const visibleMemberIds = computed(
  () => new Set(membersSorted.value.map((m) => m.id)),
);

const participations = computed(() =>
  props.speakers?.reduce((acc, speaker) => {
    const currParticipation = speaker.participations.find(
      (participation) => participation.event === props.eventId,
    );

    if (currParticipation && currParticipation.member in membersMap.value!) {
      const member = membersMap.value?.[currParticipation.member];
      if (!member) return acc; // Skip if member not found
      if (!visibleMemberIds.value.has(member.id)) return acc; // skip filtered-out members

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

const selectedStatus = ref<ParticipationStatus | null>(null);
const selectedTeamId = ref<string>("all");

const participationsFiltered = useParticipationFilter<SpeakerWithParticipation>(
  participations as ComputedRef<Map<string, SpeakerWithParticipation[]>>,
  selectedStatus,
);

// Only show members that have participations after filtering
const membersWithParticipations = computed(() => {
  if (!participationsFiltered.value) return [];
  return membersSorted.value.filter((member) =>
    participationsFiltered.value.has(member.id),
  );
});

const expanded = ref<Record<string, boolean>>({});

function isExpanded(memberId: string) {
  return expanded.value[memberId] !== undefined
    ? expanded.value[memberId]
    : true;
}

function toggleExpanded(memberId: string) {
  expanded.value[memberId] = !isExpanded(memberId);
}
</script>
