<template>
  <div class="p-4">
    <Tabs v-model="activeTab" default-value="companies" class="w-full">
      <div class="relative mb-4">
        <div class="hidden lg:flex relative items-center justify-center">
          <h1 class="text-2xl font-bold absolute left-0">
            Coordinated Members
          </h1>
          <TabsList class="grid w-full grid-cols-2 max-w-md">
            <TabsTrigger value="companies"> Companies </TabsTrigger>
            <TabsTrigger value="speakers"> Speakers </TabsTrigger>
          </TabsList>
        </div>

        <div class="lg:hidden">
          <div class="flex items-center justify-between mb-4">
            <div>
              <h1 class="text-2xl font-bold">Coordinated Members</h1>
              <div class="text-sm text-zinc-600">
                Members you coordinate for the current event
              </div>
            </div>
          </div>

          <div class="flex justify-center">
            <TabsList class="grid w-full grid-cols-2 w-4/5 sm:w-3/4">
              <TabsTrigger value="companies"> Companies </TabsTrigger>
              <TabsTrigger value="speakers"> Speakers </TabsTrigger>
            </TabsList>
          </div>
        </div>
      </div>

      <ParticipationChip v-model:selected="selectedStatus" />

      <TabsContent value="companies">
        <div v-if="isTeamsLoading || isMembersLoading" class="py-6 text-center">
          Loading…
        </div>

        <div v-else>
          <div
            v-if="
              !membersCompaniesSorted.length &&
              (isSpeakersLoading || isCompaniesLoading)
            "
            class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
          >
            <Skeleton
              v-for="i in 21"
              :key="i"
              class="h-[260px] w-full rounded-lg"
            />
          </div>

          <div v-else-if="!membersCompaniesSorted.length" class="text-center">
            <p>No coordinated company entries found</p>
          </div>

          <DynamicScroller
            v-else
            :items="membersCompaniesSorted"
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
                    v-for="entry in participationsCompanies.get(item.id) || []"
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
      </TabsContent>

      <TabsContent value="speakers">
        <div v-if="isTeamsLoading || isMembersLoading" class="py-6 text-center">
          Loading…
        </div>

        <div v-else>
          <div
            v-if="
              !membersSpeakersSorted.length &&
              (isSpeakersLoading || isCompaniesLoading)
            "
            class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
          >
            <Skeleton
              v-for="i in 21"
              :key="i"
              class="h-[260px] w-full rounded-lg"
            />
          </div>

          <div v-else-if="!membersSpeakersSorted.length" class="text-center">
            <p>No coordinated speaker entries found</p>
          </div>

          <DynamicScroller
            v-else
            :items="membersSpeakersSorted"
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
                    v-for="entry in participationsSpeakers.get(item.id) || []"
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
      </TabsContent>
    </Tabs>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

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

// Tab state
const activeTab = ref("companies");

// Separate participations maps for companies and speakers
const participationsCompanies = computed(() => {
  const m = new Map<string, CombinedEntry[]>();
  for (const [memberId, entries] of participations.value) {
    const comp = entries.filter((e) => e._type === "company");
    if (comp.length) m.set(memberId, comp);
  }
  return m;
});

const participationsSpeakers = computed(() => {
  const m = new Map<string, CombinedEntry[]>();
  for (const [memberId, entries] of participations.value) {
    const sp = entries.filter((e) => e._type === "speaker");
    if (sp.length) m.set(memberId, sp);
  }
  return m;
});

// Members lists filtered to those that have company/speaker entries
const membersCompaniesSorted = computed(() =>
  membersSorted.value.filter((m) => participationsCompanies.value.has(m.id)),
);

const membersSpeakersSorted = computed(() =>
  membersSorted.value.filter((m) => participationsSpeakers.value.has(m.id)),
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
