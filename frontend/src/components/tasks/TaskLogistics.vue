<template>
  <TaskTimelineItem
    :step-number="stepNumber"
    title="Logistics"
    :is-complete="isComplete"
    :is-last="isLast"
  >
    <template #icon>
      <Truck class="w-4 h-4" />
    </template>
    <template #header-actions>
      <StatusToggleBadge
        v-model="hasRequestedInfo"
        description="Mark whether you've asked the company for logistics info."
      />
    </template>

    <div class="space-y-4">
      <!-- Car Load/Unload Selection -->
      <div class="space-y-2">
        <Label for="car-status">Car for Loading/Unloading</Label>
        <div class="flex gap-4">
          <Select v-model="carStatus">
            <SelectTrigger class="w-[200px]">
              <SelectValue placeholder="Select an option" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="not_responded">Didn't respond</SelectItem>
              <SelectItem value="wants">Wants to bring a car</SelectItem>
              <SelectItem value="not_wants"
                >Doesn't want to bring a car</SelectItem
              >
            </SelectContent>
          </Select>

          <!-- License Plate Input (shown only when they want to bring a car) -->
          <Input
            v-if="carStatus === 'wants'"
            id="license-plate"
            v-model="licensePlate"
            placeholder="License plate"
            class="flex-1"
          />
        </div>
      </div>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import StatusToggleBadge from "./StatusToggleBadge.vue";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Truck } from "lucide-vue-next";

interface Props {
  entityId: string;
  stepNumber?: number;
  isLast?: boolean;
}

withDefaults(defineProps<Props>(), {
  stepNumber: 6,
  isLast: false,
});

type CarStatus = "not_responded" | "wants" | "not_wants";

// Request status (whether email was sent)
const hasRequestedInfo = ref<boolean>(false);

// Form data
const carStatus = ref<CarStatus>("not_responded");
const licensePlate = ref<string>("");

const isComplete = computed(() => {
  if (carStatus.value === "not_responded") return false;
  if (carStatus.value === "not_wants") return true;
  // If they want a car, they need to provide a license plate
  return carStatus.value === "wants" && licensePlate.value.trim() !== "";
});

defineExpose({
  isComplete,
});
</script>
