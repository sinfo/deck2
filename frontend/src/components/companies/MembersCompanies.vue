<template>
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold">Companies</h1>
    <CreateCompanyDialogTrigger />
  </div>

  <ParticipationChip v-model:selected="selectedStatus" />

  <div
    v-if="!membersSorted.length && companiesLoading"
    class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
  >
    <Skeleton v-for="i in 21" :key="i" class="h-[260px] w-full rounded-lg" />
  </div>

  <div v-else-if="!companies.length && !companiesLoading" class="text-center">
    <p>No companies found</p>
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
          <CompanyWorkflowCard
            v-for="company in participationsFiltered?.get(item.id) || []"
            :key="company.id"
            :company="company"
          />
        </div>
      </div>
    </template>
  </DynamicScroller>
</template>

<script setup lang="ts">
import type { Company, CompanyParticipation } from "@/dto/companies";
import type { Member } from "@/dto/members";
import MemberWithAvatar from "@/components/members/MemberWithAvatar.vue";
import { DynamicScroller } from "vue-virtual-scroller";
import { useInsertionSort, useSortByParticipationStatus } from "@/lib/utils";
import { Skeleton } from "../ui/skeleton";
import CompanyWorkflowCard from "../cards/CompanyWorkflowCard.vue";
import CreateCompanyDialogTrigger from "./CreateCompanyDialogTrigger.vue";
import ParticipationChip from "@/components/ParticipationChip.vue";
import { ref, computed, type ComputedRef } from "vue";
import { ChevronDown } from "lucide-vue-next";
import { useParticipationFilter } from "@/composables/useParticipationFilter";
import type { ParticipationStatus } from "@/dto";

const props = defineProps<{
  companies: Company[];
  companiesLoading?: boolean;
  members: Member[];
  eventId: number;
}>();

// TODO shift me to top
const membersSorted = computed(() => {
  return [...props.members]?.sort((a, b) => a.name.localeCompare(b.name));
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

const participationsFiltered = useParticipationFilter<CompanyWithParticipation>(
  participations as ComputedRef<Map<string, CompanyWithParticipation[]>>,
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
