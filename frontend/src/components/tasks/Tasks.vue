<template>
  <div class="p-4 space-y-6">
    <h2 class="text-lg font-semibold">
      {{ entityType === "company" ? "Company" : "Speaker" }} Tasks Timeline
    </h2>

    <!-- Stepper Container -->
    <Stepper
      v-model="currentStep"
      orientation="vertical"
      :linear="false"
      class="flex flex-col"
    >
      <TaskConfirmation
        :entity-id="entityId"
        :entity-type="entityType"
        :participation="currentParticipation"
        @package-changed="onPackageChanged"
      />

      <TaskBillingLogos
        :entity-type="entityType"
        :billing-info="billingInfo"
        :entity-id="entityId"
      />

      <TaskContract :entity-type="entityType" :entity-id="entityId" />

      <!-- Company-only steps -->
      <template v-if="entityType === 'company'">
        <TaskSessionTitles
          v-if="showSessionTitles"
          :package-items="packageItems"
        />

        <TaskCorlief
          :entity-id="entityId"
          :step-number="showSessionTitles ? 5 : 4"
        />

        <TaskLogistics
          :entity-id="entityId"
          :step-number="showSessionTitles ? 6 : 5"
          :is-last="true"
        />
      </template>

      <!-- Speaker-only steps -->
      <template v-if="entityType === 'speaker'">
        <TaskFlights :entity-id="entityId" :step-number="4" />

        <TaskMaterials :entity-id="entityId" :step-number="5" />

        <TaskHotel :entity-id="entityId" :step-number="6" :is-last="true" />
      </template>
    </Stepper>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import type { EntityType } from "@/dto/tasks";
import type { CompanyBillingInfo, CompanyParticipation } from "@/dto/companies";
import type { SpeakerParticipation } from "@/dto/speakers";
import type { Item } from "@/dto/item";
import { Stepper } from "@/components/ui/stepper";
import TaskConfirmation from "./TaskConfirmation.vue";
import TaskBillingLogos from "./TaskBillingLogos.vue";
import TaskContract from "./TaskContract.vue";
import TaskSessionTitles from "./TaskSessionTitles.vue";
import TaskCorlief from "./TaskCorlief.vue";
import TaskLogistics from "./TaskLogistics.vue";
import TaskFlights from "./TaskFlights.vue";
import TaskMaterials from "./TaskMaterials.vue";
import TaskHotel from "./TaskHotel.vue";

interface Props {
  entityType: EntityType;
  entityId: string;
  participation?: CompanyParticipation | SpeakerParticipation;
  billingInfo?: CompanyBillingInfo;
}

const props = defineProps<Props>();

// Get current participation
const currentParticipation = computed(() => props.participation);

// Package items for session titles
const packageItems = ref<Item[]>([]);

const onPackageChanged = (_name: string, items: Item[]) => {
  packageItems.value = items;
};

// Show session titles only if package has presentation or workshop items
// (only relevant for companies that have packages)
const showSessionTitles = computed(() => {
  if (props.entityType !== "company") return false;
  return packageItems.value.some(
    (item) =>
      item.name?.toLowerCase() === "presentation" ||
      item.name?.toLowerCase() === "workshop",
  );
});

// Set current step to 0 so the stepper doesn't auto-mark any steps as completed
const currentStep = ref(0);
</script>
