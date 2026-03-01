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
      <!-- Arrival -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Arrival</span>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div class="space-y-1">
            <Label for="arrival-airport" class="text-xs"
              >Airport (origin)</Label
            >
            <Input
              id="arrival-airport"
              v-model="arrivalAirport"
              placeholder="e.g. JFK"
            />
          </div>
          <div class="space-y-1">
            <Label for="arrival-flight" class="text-xs">Flight Nº</Label>
            <Input
              id="arrival-flight"
              v-model="arrivalFlightNumber"
              placeholder="e.g. TP1234"
            />
          </div>
          <div class="space-y-1">
            <Label for="arrival-date" class="text-xs">Date (arrival LIS)</Label>
            <DatePicker v-model="arrivalDate" placeholder="Pick a date" />
          </div>
          <div class="space-y-1">
            <Label for="arrival-time" class="text-xs">Time (arrival LIS)</Label>
            <Input
              id="arrival-time"
              v-model="arrivalTime"
              placeholder="e.g. 14:30"
            />
          </div>
        </div>
      </div>

      <Separator />

      <!-- Departure -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Departure</span>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div class="space-y-1">
            <Label for="departure-airport" class="text-xs"
              >Airport (destination)</Label
            >
            <Input
              id="departure-airport"
              v-model="departureAirport"
              placeholder="e.g. JFK"
            />
          </div>
          <div class="space-y-1">
            <Label for="departure-flight" class="text-xs">Flight Nº</Label>
            <Input
              id="departure-flight"
              v-model="departureFlightNumber"
              placeholder="e.g. TP1235"
            />
          </div>
          <div class="space-y-1">
            <Label for="departure-date" class="text-xs">Date (from LIS)</Label>
            <DatePicker v-model="departureDate" placeholder="Pick a date" />
          </div>
          <div class="space-y-1">
            <Label for="departure-time" class="text-xs">Time (from LIS)</Label>
            <Input
              id="departure-time"
              v-model="departureTime"
              placeholder="e.g. 10:00"
            />
          </div>
        </div>
      </div>

      <Separator />

      <!-- Details -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Details</span>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div class="space-y-1">
            <Label for="flight-price" class="text-xs">Price</Label>
            <Input
              id="flight-price"
              v-model="flightPrice"
              placeholder="e.g. 350.00"
            />
          </div>
          <div class="space-y-1">
            <Label for="flight-status" class="text-xs">Status</Label>
            <Select v-model="flightStatus">
              <SelectTrigger>
                <SelectValue placeholder="Select status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="received">Info Received</SelectItem>
                <SelectItem value="approved">Approved</SelectItem>
                <SelectItem value="bought">Bought</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div class="space-y-1">
            <Label for="flight-link" class="text-xs">Link (if we buy)</Label>
            <Input
              id="flight-link"
              v-model="flightLink"
              placeholder="Booking link"
            />
          </div>
          <div class="space-y-1">
            <Label for="flight-booking-ref" class="text-xs">Booking Ref</Label>
            <Input
              id="flight-booking-ref"
              v-model="flightBookingRef"
              placeholder="Reference code"
            />
          </div>
        </div>
      </div>

      <Separator />

      <!-- Refund -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Refund</span>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div class="space-y-1">
            <Label for="refund-amount" class="text-xs">Amount (EUR)</Label>
            <Input
              id="refund-amount"
              v-model="refundAmount"
              placeholder="e.g. 350.00"
            />
          </div>
          <div class="space-y-1">
            <Label for="refund-method" class="text-xs">Method</Label>
            <Input
              id="refund-method"
              v-model="refundMethod"
              placeholder="e.g. Bank transfer"
            />
          </div>
          <div class="space-y-1">
            <Label for="refund-info" class="text-xs">Info needed</Label>
            <Input
              id="refund-info"
              v-model="refundInfoNeeded"
              placeholder="e.g. IBAN"
            />
          </div>
          <div class="space-y-1">
            <Label for="refund-status" class="text-xs">Status</Label>
            <Select v-model="refundStatus">
              <SelectTrigger>
                <SelectValue placeholder="Select status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="not_started">Not started</SelectItem>
                <SelectItem value="receipt_requested"
                  >Receipt requested</SelectItem
                >
                <SelectItem value="info_requested">Info requested</SelectItem>
                <SelectItem value="done">Done</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      </div>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import StatusToggleBadge from "./StatusToggleBadge.vue";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Separator } from "@/components/ui/separator";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { DatePicker } from "@/components/ui/date-picker";
import { Plane } from "lucide-vue-next";
import type { SpeakerTasks, SpeakerTaskFlights } from "@/dto/tasks";

interface Props {
  entityId: string;
  stepNumber?: number;
  speakerTasks?: SpeakerTasks;
}

const props = withDefaults(defineProps<Props>(), {
  stepNumber: 3,
  speakerTasks: undefined,
});

const emit = defineEmits<{
  "update:flights": [value: SpeakerTaskFlights];
}>();

const parseDate = (v: string | null | undefined): Date | null => {
  if (!v) return null;
  try {
    return new Date(v);
  } catch {
    return null;
  }
};

// Request status
const hasRequestedFlights = ref<boolean>(
  props.speakerTasks?.flights?.requested ?? false,
);

// Arrival
const arrivalAirport = ref<string>(
  props.speakerTasks?.flights?.arrival?.airport ?? "",
);
const arrivalFlightNumber = ref<string>(
  props.speakerTasks?.flights?.arrival?.flightNumber ?? "",
);
const arrivalDate = ref<Date | null>(
  parseDate(props.speakerTasks?.flights?.arrival?.date),
);
const arrivalTime = ref<string>(
  props.speakerTasks?.flights?.arrival?.time ?? "",
);

// Departure
const departureAirport = ref<string>(
  props.speakerTasks?.flights?.departure?.airport ?? "",
);
const departureFlightNumber = ref<string>(
  props.speakerTasks?.flights?.departure?.flightNumber ?? "",
);
const departureDate = ref<Date | null>(
  parseDate(props.speakerTasks?.flights?.departure?.date),
);
const departureTime = ref<string>(
  props.speakerTasks?.flights?.departure?.time ?? "",
);

// Details
const flightPrice = ref<string>(
  props.speakerTasks?.flights?.details?.price ?? "",
);
const flightStatus = ref<string>(
  props.speakerTasks?.flights?.details?.status ?? "pending",
);
const flightLink = ref<string>(
  props.speakerTasks?.flights?.details?.link ?? "",
);
const flightBookingRef = ref<string>(
  props.speakerTasks?.flights?.details?.bookingRef ?? "",
);

// Refund
const refundAmount = ref<string>(
  props.speakerTasks?.flights?.refund?.amount ?? "",
);
const refundMethod = ref<string>(
  props.speakerTasks?.flights?.refund?.method ?? "",
);
const refundInfoNeeded = ref<string>(
  props.speakerTasks?.flights?.refund?.infoNeeded ?? "",
);
const refundStatus = ref<string>(
  props.speakerTasks?.flights?.refund?.status ?? "not_started",
);

function emitFlights() {
  emit("update:flights", {
    requested: hasRequestedFlights.value,
    arrival: {
      airport: arrivalAirport.value,
      flightNumber: arrivalFlightNumber.value,
      date: arrivalDate.value?.toISOString() ?? null,
      time: arrivalTime.value,
    },
    departure: {
      airport: departureAirport.value,
      flightNumber: departureFlightNumber.value,
      date: departureDate.value?.toISOString() ?? null,
      time: departureTime.value,
    },
    details: {
      price: flightPrice.value,
      status: flightStatus.value,
      link: flightLink.value,
      bookingRef: flightBookingRef.value,
    },
    refund: {
      amount: refundAmount.value,
      method: refundMethod.value,
      infoNeeded: refundInfoNeeded.value,
      status: refundStatus.value,
    },
  });
}

watch(
  [
    hasRequestedFlights,
    arrivalAirport,
    arrivalFlightNumber,
    arrivalDate,
    arrivalTime,
    departureAirport,
    departureFlightNumber,
    departureDate,
    departureTime,
    flightPrice,
    flightStatus,
    flightLink,
    flightBookingRef,
    refundAmount,
    refundMethod,
    refundInfoNeeded,
    refundStatus,
  ],
  emitFlights,
);

const isComplete = computed(() => {
  return flightStatus.value === "bought";
});

defineExpose({
  isComplete,
});
</script>
