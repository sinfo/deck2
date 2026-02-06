<template>
  <div class="p-4 space-y-6">
    <h2 class="text-lg font-semibold">Company Tasks Timeline</h2>

    <!-- Stepper Container -->
    <Stepper
      v-model="currentStep"
      orientation="vertical"
      :linear="false"
      class="flex flex-col"
    >
      <TaskConfirmation
        :company-id="companyWithParticipation.id"
        :participation="currentParticipation"
        @package-changed="onPackageChanged"
      />

      <TaskBillingLogos
        :billing-info="companyWithParticipation.billingInfo"
        :company-id="companyWithParticipation.id"
      />

      <TaskContract :company-id="companyWithParticipation.id" />

      <TaskSessionTitles
        v-if="showSessionTitles"
        :package-items="packageItems"
      />

      <TaskCorlief
        :company-id="companyWithParticipation.id"
        :step-number="showSessionTitles ? 5 : 4"
      />

      <TaskLogistics
        :company-id="companyWithParticipation.id"
        :step-number="showSessionTitles ? 6 : 5"
        :is-last="true"
      />
    </Stepper>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import type { CompanyWithParticipation } from "@/dto/companies";
import type { Item } from "@/dto/item";
import { Stepper } from "@/components/ui/stepper";
import TaskConfirmation from "../../../../components/tasks/TaskConfirmation.vue";
import TaskBillingLogos from "../../../../components/tasks/TaskBillingLogos.vue";
import TaskContract from "../../../../components/tasks/TaskContract.vue";
import TaskSessionTitles from "../../../../components/tasks/TaskSessionTitles.vue";
import TaskCorlief from "../../../../components/tasks/TaskCorlief.vue";
import TaskLogistics from "../../../../components/tasks/TaskLogistics.vue";

interface Props {
  companyWithParticipation: CompanyWithParticipation;
}

const props = defineProps<Props>();

// Get current participation
const currentParticipation = computed(
  () => props.companyWithParticipation?.participation,
);

// Package items for session titles
const packageItems = ref<Item[]>([]);

const onPackageChanged = (_name: string, items: Item[]) => {
  packageItems.value = items;
};

// Show session titles only if package has presentation or workshop items
const showSessionTitles = computed(() => {
  return packageItems.value.some(
    (item) =>
      item.name?.toLowerCase() === "presentation" ||
      item.name?.toLowerCase() === "workshop",
  );
});

// Set current step to 0 so the stepper doesn't auto-mark any steps as completed
const currentStep = ref(0);
</script>
