<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h2 class="text-2xl font-semibold">Leaderboard</h2>

      <div class="flex items-center gap-3">
        <label class="text-sm text-muted-foreground">Filter status</label>
        <select v-model="selectedStatus" class="border rounded px-2 py-1">
          <option value="">All</option>
          <option
            v-for="(label, key) in humanReadableParticipationStatus"
            :key="key"
            :value="key"
          >
            {{ label }}
          </option>
        </select>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <LeaderboardCard
        title="Companies invited"
        :rows="companyLeaderboard"
        :loading="isLoadingCompanies || isLoadingMembers"
        item-label="companies"
      />

      <LeaderboardCard
        title="Speakers invited"
        :rows="speakerLeaderboard"
        :loading="isLoadingSpeakers || isLoadingMembers"
        item-label="speakers"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import { useQuery } from "@pinia/colada";
import { getAllCompanies } from "@/api/companies";
import { getAllSpeakers } from "@/api/speakers";
import { getAllMembers } from "@/api/members";
import type { Company } from "@/dto/companies";
import type { Speaker } from "@/dto/speakers";
import type { Member } from "@/dto/members";
import { useEventStore } from "@/stores/event";
import LeaderboardCard from "@/components/Leaderboard/LeaderboardCard.vue";
import { humanReadableParticipationStatus } from "@/dto";
// icons are used inside LeaderboardCard

const BOT_ACCOUNTS = new Set([
  "ToolBot!",
  "zzPartnerships",
  "zzPartnernerships",
]);

const eventStore = useEventStore();
const selectedStatus = ref<string>("");

const companiesFilters = computed(() => ({
  event: eventStore.selectedEvent?.id,
}));
const speakersFilters = computed(() => ({
  event: eventStore.selectedEvent?.id,
}));
const membersFilters = computed(() => ({
  event: eventStore.selectedEvent?.id,
}));

const { data: companiesData, isLoading: isLoadingCompanies } = useQuery({
  key: () => ["leaderboard-companies", JSON.stringify(companiesFilters.value)],
  query: () => getAllCompanies(companiesFilters.value),
});

const { data: speakersData, isLoading: isLoadingSpeakers } = useQuery({
  key: () => ["leaderboard-speakers", JSON.stringify(speakersFilters.value)],
  query: () => getAllSpeakers(speakersFilters.value),
});

const { data: membersData, isLoading: isLoadingMembers } = useQuery({
  key: () => ["leaderboard-members", JSON.stringify(membersFilters.value)],
  query: () => getAllMembers(membersFilters.value),
});

type LeaderRow = {
  memberId: string;
  count: number;
  items: string[]; // names
  member: Member;
};
type RankedLeaderRow = LeaderRow & { rank: number };

// Helper function to compute ranks with ties
function computeRanks(rows: LeaderRow[]): RankedLeaderRow[] {
  const sorted = [...rows].sort((a, b) => b.count - a.count);
  const ranked: RankedLeaderRow[] = [];
  let prevCount: number | null = null;
  let prevRank = 0;
  for (let i = 0; i < sorted.length; i++) {
    const item = sorted[i];
    const rank =
      prevCount !== null && item.count === prevCount ? prevRank : prevRank + 1;
    prevCount = item.count;
    prevRank = rank;
    ranked.push({ ...item, rank });
  }
  return ranked;
}

// Generic helper to build leaderboards from any collection (companies or speakers)
function computeLeaderboardFrom<
  TItem,
  TParticipation extends { event?: number; status?: string; member?: unknown },
>(
  items: TItem[],
  getParticipations: (it: TItem) => TParticipation[] | undefined,
  getName: (it: TItem) => string,
  botSet = BOT_ACCOUNTS,
): RankedLeaderRow[] {
  const rows = new Map<string, LeaderRow>();
  const eventId = eventStore.selectedEvent?.id;

  items.forEach((it: TItem) => {
    (getParticipations(it) || []).forEach((p: TParticipation) => {
      if (p.event !== eventId) return;
      if (selectedStatus.value && p.status !== selectedStatus.value) return;
      if (!p.member) return;
      const id = p.member as string;
      const entry: LeaderRow =
        rows.get(id) ||
        ({
          memberId: id,
          count: 0,
          items: [] as string[],
          member: { id, name: "Unknown", img: "", sinfoid: "" } as Member,
        } as LeaderRow);
      entry.count += 1;
      entry.items.push(getName(it));
      rows.set(id, entry);
    });
  });

  const arr = Array.from(rows.values());
  // attach member objects
  arr.forEach((r) => {
    r.member =
      membersData.value?.data?.find((m: Member) => m.id === r.memberId) ||
      ({ id: r.memberId, name: "Unknown", img: "", sinfoid: "" } as Member);
  });

  // filter out bot accounts by name or sinfoid
  const filtered = arr.filter((r) => {
    const name = (r.member?.name || "") as string;
    const sinfoid = (r.member?.sinfoid || "") as string;
    return !botSet.has(name) && !botSet.has(sinfoid);
  });

  return computeRanks(filtered);
}

const companyLeaderboard = computed<RankedLeaderRow[]>(() => {
  const companies = (companiesData.value?.data || []) as Company[];
  return computeLeaderboardFrom(
    companies,
    (c: Company) => c.participations,
    (c: Company) => c.name,
  );
});

const speakerLeaderboard = computed<RankedLeaderRow[]>(() => {
  const speakers = (speakersData.value?.data || []) as Speaker[];
  return computeLeaderboardFrom(
    speakers,
    (s: Speaker) => s.participations,
    (s: Speaker) => s.name,
  );
});
</script>

<style scoped>
.leader-row img {
  border-radius: 0.375rem;
}
</style>
