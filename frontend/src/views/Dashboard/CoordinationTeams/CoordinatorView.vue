<template>
  <div class="p-4">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold">Coordinated Members</h1>
        <div class="text-sm text-zinc-600">
          Members you coordinate for the current event
        </div>
      </div>
    </div>

    <ParticipationChip v-model:selected="selectedStatus" />

    <div v-if="isTeamsLoading || isMembersLoading" class="py-6 text-center">
      Loading…
    </div>

    <div v-else>
      <div
        v-if="
          !membersSorted.length && (isSpeakersLoading || isCompaniesLoading)
        "
        class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
      >
        <Skeleton
          v-for="i in 21"
          :key="i"
          class="h-[260px] w-full rounded-lg"
        />
      </div>

      <div v-else-if="!membersSorted.length" class="text-center">
        <p>No coordinated members found</p>
      </div>

      <DynamicScroller
        v-else
        :items="membersSorted"
        class="h-100"
        :min-item-size="1"
      >
        <template #default="{ item }">
          <div class="w-full border-b border-muted-foreground/10 pb-4 mb-4">
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
              <component
                :is="entry._type === 'speaker' ? SWC : CWC"
                v-for="entry in participationsFiltered?.get(item.id) || []"
                :key="entry.id"
                v-bind="
                  entry._type === 'speaker'
                    ? { speaker: entry }
                    : { company: entry }
                "
              />
            </div>
          </div>
        </template>
      </DynamicScroller>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, type ComputedRef } from "vue";
import { useQuery } from "@pinia/colada";
import { useEventStore } from "@/stores/event";
import { getMyCoordinationTeams } from "@/api/coordinationTeams";
import { getSpeakersByMembers } from "@/api/speakers";
import { getCompaniesByMembers } from "@/api/companies";
import { getMemberById } from "@/api/members";

import type {
  Speaker,
  SpeakerWithParticipation,
  SpeakerParticipation,
} from "@/dto/speakers";
import type {
  Company,
  CompanyWithParticipation,
  CompanyParticipation,
} from "@/dto/companies";
import type { ParticipationStatus } from "@/dto";
import type { Member } from "@/dto/members";

import { DynamicScroller } from "vue-virtual-scroller";
import MemberWithAvatar from "@/components/members/MemberWithAvatar.vue";
import SpeakerWorkflowCard from "@/components/cards/SpeakerWorkflowCard.vue";
import CompanyWorkflowCard from "@/components/cards/CompanyWorkflowCard.vue";
import ParticipationChip from "@/components/ParticipationChip.vue";
import { Skeleton } from "@/components/ui/skeleton";
import { ChevronDown } from "lucide-vue-next";
import { useInsertionSort, useSortByParticipationStatus } from "@/lib/utils";
import { useParticipationFilter } from "@/composables/useParticipationFilter";

// component references used by dynamic component
const SWC = SpeakerWorkflowCard;
const CWC = CompanyWorkflowCard;

// fetch coordination teams where current user is coordinator
const { data: teamsData, isLoading: isTeamsLoading } = useQuery({
  key: ["coordinationTeams", "me"],
  query: () => getMyCoordinationTeams(),
});

const teams = computed(() => teamsData.value?.data || []);

// collect unique member ids across teams
const memberIds = computed(() => {
  const set = new Set<string>();
  for (const t of teams.value) {
    if (t.coordinatedMembers) {
      for (const m of t.coordinatedMembers) set.add(m);
    }
  }
  return Array.from(set);
});

// fetch speakers and companies for those members (single call each)
const { data: speakersData, isLoading: isSpeakersLoading } = useQuery({
  key: () => ["coordinationTeams", "speakers", memberIds.value.join(",")],
  query: async (): Promise<Speaker[]> => {
    if (!memberIds.value.length) return [];
    const res = await getSpeakersByMembers(memberIds.value);
    return res.data || [];
  },
});

const { data: companiesData, isLoading: isCompaniesLoading } = useQuery({
  key: () => ["coordinationTeams", "companies", memberIds.value.join(",")],
  query: async (): Promise<Company[]> => {
    if (!memberIds.value.length) return [];
    const res = await getCompaniesByMembers(memberIds.value);
    return res.data || [];
  },
});

// fetch Member objects for the memberIds (parallel)
const { data: membersData, isLoading: isMembersLoading } = useQuery({
  key: () => ["coordinationTeams", "members", memberIds.value.join(",")],
  query: async (): Promise<Member[]> => {
    if (!memberIds.value.length) return [];
    const calls = memberIds.value.map((m) => getMemberById(m));
    const results = await Promise.all(calls);
    return results.map((r) => r.data);
  },
});

const speakersList = computed(() => speakersData.value || []);
const companiesList = computed(() => companiesData.value || []);
const membersList = computed(() => membersData.value || []);

const eventStore = useEventStore();
const eventId = computed(() => eventStore.selectedEvent?.id || 0);

// Prepare members sorted and map
const membersSorted = computed(() => {
  return [...membersList.value]?.sort((a, b) => a.name.localeCompare(b.name));
});

const membersMap = computed(() => {
  return membersList.value?.reduce(
    (acc, member) => {
      acc[member.id] = member;
      return acc;
    },
    {} as Record<string, Member>,
  );
});

// Build combined participations per member (speakers + companies)
type CombinedEntry =
  | (SpeakerWithParticipation & { _type: "speaker" })
  | (CompanyWithParticipation & { _type: "company" });

const participations = computed(() =>
  ((): Map<string, CombinedEntry[]> => {
    const acc = new Map<string, CombinedEntry[]>();

    // add speakers
    for (const s of speakersList.value) {
      const curr = s.participations.find(
        (p): p is SpeakerParticipation => p.event === eventId.value,
      );
      if (!curr) continue;
      const memberId = curr.member;
      if (!membersMap.value || !(memberId in membersMap.value)) continue;

      if (!acc.has(memberId)) acc.set(memberId, []);

      useInsertionSort(
        acc.get(memberId)!,
        { ...s, participation: curr, _type: "speaker" as const },
        (a: CombinedEntry, b: CombinedEntry) =>
          useSortByParticipationStatus(a.participation, b.participation),
      );
    }

    // add companies
    for (const c of companiesList.value) {
      const curr = c.participations.find(
        (p): p is CompanyParticipation => p.event === eventId.value,
      );
      if (!curr) continue;
      const memberId = curr.member;
      if (!membersMap.value || !(memberId in membersMap.value)) continue;

      if (!acc.has(memberId)) acc.set(memberId, []);

      useInsertionSort(
        acc.get(memberId)!,
        { ...c, participation: curr, _type: "company" as const },
        (a: CombinedEntry, b: CombinedEntry) =>
          useSortByParticipationStatus(a.participation, b.participation),
      );
    }

    return acc;
  })(),
);

const selectedStatus = ref<ParticipationStatus | null>(null);

const participationsFiltered = useParticipationFilter<CombinedEntry>(
  participations as ComputedRef<Map<string, CombinedEntry[]>>,
  selectedStatus,
);

// Track expanded/collapsed state per member. Default to expanded (true)
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

<style scoped></style>
