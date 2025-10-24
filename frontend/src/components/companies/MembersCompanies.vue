<template>
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold">Companies</h1>
    <CreateCompanyDialogTrigger />
  </div>

  <div
    class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
    v-if="!membersSorted.length && companiesLoading"
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
    <template v-slot="{ item }">
      <MemberWithAvatar :member="item" with-separator />

      <div
        class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
      >
        <CompanyWorkflowCard
          v-for="company in participations?.get(item.id) || []"
          :key="company.id"
          :company="company"
        />
      </div>
    </template>
  </DynamicScroller>
</template>

<script setup lang="ts">
import { computed } from "vue";
import type { Company, CompanyParticipation } from "@/dto/companies";
import type { Member } from "@/dto/members";
import MemberWithAvatar from "@/components/members/MemberWithAvatar.vue";
import { DynamicScroller } from "vue-virtual-scroller";
import { useInsertionSort, useSortByParticipationStatus } from "@/lib/utils";
import { Skeleton } from "../ui/skeleton";
import CompanyWorkflowCard from "../cards/CompanyWorkflowCard.vue";
import CreateCompanyDialogTrigger from "./CreateCompanyDialogTrigger.vue";

const props = defineProps<{
  companies: Company[];
  companiesLoading?: boolean;
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
</script>
