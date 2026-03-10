<template>
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold">Companies</h1>
    <div class="flex items-center gap-2">
      <AlertDialog v-if="isCoordinator" v-model:open="showAnnounceDialog">
        <AlertDialogTrigger as-child>
          <Button
            size="sm"
            variant="outline"
            :disabled="announcing || acceptedCount === 0"
          >
            <Megaphone class="w-4 h-4 mr-1" />
            Announce All ({{ acceptedCount }})
          </Button>
        </AlertDialogTrigger>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Announce All Accepted Companies</AlertDialogTitle>
            <AlertDialogDescription>
              This will change
              <strong>{{ acceptedCount }}</strong> accepted
              {{ acceptedCount === 1 ? "company" : "companies" }} to announced
              for the current event. This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel :disabled="announcing">Cancel</AlertDialogCancel>
            <Button :disabled="announcing" @click="handleAnnounce">
              {{ announcing ? "Announcing..." : "Announce All" }}
            </Button>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
      <CreateCompanyDialogTrigger />
    </div>
  </div>

  <div class="flex flex-wrap gap-3 mb-4 items-center">
    <ParticipationFilters
      v-model:selected="selectedStatus"
      v-model:selected-package="selectedPackage"
      :packages="packages"
    />
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
    v-if="!membersSorted.length && companiesLoading"
    class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
  >
    <Skeleton v-for="i in 21" :key="i" class="h-[260px] w-full rounded-lg" />
  </div>

  <div
    v-else-if="!membersWithParticipations.length && !companiesLoading"
    class="text-center"
  >
    <p>No companies found</p>
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
        <CompanyWorkflowCard
          v-for="company in participationsFiltered?.get(item.id) || []"
          :key="company.id"
          :company="company"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Company, CompanyParticipation } from "@/dto/companies";
import type { Member } from "@/dto/members";
import type { CoordinationTeam } from "@/dto/coordinationTeams";
import MemberWithAvatar from "@/components/members/MemberWithAvatar.vue";
import { useInsertionSort, useSortByParticipationStatus } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import CompanyWorkflowCard from "../cards/CompanyWorkflowCard.vue";
import CreateCompanyDialogTrigger from "./CreateCompanyDialogTrigger.vue";
import { ref, computed, type ComputedRef } from "vue";
import { ChevronDown, Megaphone } from "lucide-vue-next";
import { useParticipationFilter } from "@/composables/useParticipationFilter";
import type { ObjectID, ParticipationStatus } from "@/dto";
import ParticipationFilters from "@/components/ParticipationFilters.vue";
import { useEventPackagesQuery } from "@/mutations/packages";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useQueryCache } from "@pinia/colada";
import { announceAcceptedCompanies } from "@/api/companies";
import { useToast } from "@/lib/toast";
import Button from "@/components/ui/button/Button.vue";
import { usePermissions } from "@/composables/usePermissions";
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

const props = defineProps<{
  companies: Company[];
  companiesLoading?: boolean;
  members: Member[];
  eventId: number;
  coordinationTeams?: CoordinationTeam[];
}>();

// Coordinator check
const { isCoordinatorOrAdmin: isCoordinator } = usePermissions();

// Count of accepted companies in current event
const acceptedCount = computed(() => {
  return props.companies.filter((c) =>
    c.participations.some(
      (p) => p.event === props.eventId && p.status === "ACCEPTED",
    ),
  ).length;
});

// Announce all accepted companies
const showAnnounceDialog = ref(false);
const announcing = ref(false);
const queryCache = useQueryCache();
const { toast } = useToast();

async function handleAnnounce() {
  announcing.value = true;
  try {
    const res = await announceAcceptedCompanies();
    const count = res.data.announced;
    toast.success({
      title: "Companies announced",
      description: `${count} ${count === 1 ? "company" : "companies"} changed from accepted to announced.`,
    });
    queryCache.invalidateQueries({ key: ["companies"] });
  } catch (err) {
    toast.error({
      title: "Failed to announce companies",
      description: err instanceof Error ? err.message : "An error occurred",
    });
  } finally {
    announcing.value = false;
    showAnnounceDialog.value = false;
  }
}

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

interface CompanyWithParticipation extends Company {
  participation: CompanyParticipation;
}

const participations = computed(() =>
  props.companies?.reduce((acc, company) => {
    const currParticipation = company.participations.find(
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
          ...company,
          participation: currParticipation,
        },
        (a, b) =>
          useSortByParticipationStatus(a.participation, b.participation),
      );
    }

    return acc;
  }, new Map<string, CompanyWithParticipation[]>()),
);

const selectedStatus = ref<ParticipationStatus | null>(null);
const selectedPackage = ref<ObjectID | null>(null);
const selectedTeamId = ref<string>("all");

// Fetch packages for filter, pre-filtered by current event
const { data: packages } = useEventPackagesQuery();

const participationsFiltered = useParticipationFilter<CompanyWithParticipation>(
  participations as ComputedRef<Map<string, CompanyWithParticipation[]>>,
  selectedStatus,
  selectedPackage,
);

// Only show members that have participations after filtering
const membersWithParticipations = computed(() => {
  if (!participationsFiltered.value) return [];
  return membersSorted.value.filter((member) =>
    participationsFiltered.value.has(member.id),
  );
});

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
