<template>
  <TaskTimelineItem
    :step-number="stepNumber"
    title="Flights"
    :is-complete="isComplete"
  >
    <template #icon>
      <Plane class="w-4 h-4" />
    </template>
    <template #header-actions>
      <StatusToggleBadge
        v-model="hasRequestedFlights"
        active-label="Requested"
        inactive-label="Not Requested"
        description="Mark whether you've asked the speaker for flight info."
      />
    </template>

    <div class="space-y-4">
      <!-- Flight booking flow -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Booking</span>

        <div class="flex items-center space-x-2">
          <Checkbox id="flights-received" v-model="flightsReceived" />
          <Label for="flights-received" class="text-sm">
            Flights info received
          </Label>
        </div>

        <div class="flex items-center space-x-2">
          <Checkbox id="flights-approved" v-model="flightsApproved" />
          <Label for="flights-approved" class="text-sm">
            Flights approved
          </Label>
        </div>

        <div class="flex items-center space-x-2">
          <Checkbox id="flights-bought" v-model="flightsBought" />
          <Label for="flights-bought" class="text-sm"> Flights bought </Label>
        </div>
      </div>

      <Separator />

      <!-- Refund flow -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Refund</span>

        <div class="flex items-center space-x-2">
          <Checkbox id="receipt-requested" v-model="receiptRequested" />
          <Label for="receipt-requested" class="text-sm">
            Receipt requested
          </Label>
        </div>

        <div class="flex items-center space-x-2">
          <Checkbox id="refund-info-requested" v-model="refundInfoRequested" />
          <Label for="refund-info-requested" class="text-sm">
            Refund info requested
          </Label>
        </div>

        <div class="flex items-center space-x-2">
          <Checkbox id="refund-done" v-model="refundDone" />
          <Label for="refund-done" class="text-sm"> Refund done </Label>
        </div>
      </div>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import StatusToggleBadge from "./StatusToggleBadge.vue";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { Plane } from "lucide-vue-next";

interface Props {
  entityId: string;
  stepNumber?: number;
}

withDefaults(defineProps<Props>(), {
  stepNumber: 4,
});

// Flight booking states
const hasRequestedFlights = ref<boolean>(false);
const flightsReceived = ref<boolean>(false);
const flightsApproved = ref<boolean>(false);
const flightsBought = ref<boolean>(false);

// Refund states
const receiptRequested = ref<boolean>(false);
const refundInfoRequested = ref<boolean>(false);
const refundDone = ref<boolean>(false);

const isComplete = computed(() => {
  return flightsBought.value === true && refundDone.value === true;
});

defineExpose({
  isComplete,
});
</script>
