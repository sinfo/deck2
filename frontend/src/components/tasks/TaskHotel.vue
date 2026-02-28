<template>
  <TaskTimelineItem
    :step-number="stepNumber"
    title="Hotel"
    :is-complete="isComplete"
    :is-last="isLast"
  >
    <template #icon>
      <Hotel class="w-4 h-4" />
    </template>
    <template #header-actions>
      <StatusToggleBadge
        v-model="hasRequestedHotelInfo"
        active-label="Requested"
        inactive-label="Not Requested"
        description="Mark whether you've asked the speaker for hotel info."
      />
    </template>

    <div class="space-y-4">
      <!-- Hotel Details -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Details</span>
        <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
          <div class="space-y-1">
            <Label for="hotel-name" class="text-xs">Hotel Name</Label>
            <Input
              id="hotel-name"
              v-model="hotelName"
              placeholder="e.g. Hotel Marques"
            />
          </div>
          <div class="space-y-1">
            <Label for="room-type" class="text-xs">Room Type</Label>
            <Input
              id="room-type"
              v-model="roomType"
              placeholder="e.g. Single, Double"
            />
          </div>
          <div class="space-y-1">
            <Label for="hotel-price" class="text-xs">Price</Label>
            <Input
              id="hotel-price"
              v-model="hotelPrice"
              placeholder="e.g. 120.00"
            />
          </div>
        </div>
      </div>

      <Separator />

      <!-- Booking -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Booking</span>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div class="space-y-1">
            <Label for="check-in" class="text-xs">Check-In</Label>
            <DatePicker v-model="checkInDate" placeholder="Check-in date" />
          </div>
          <div class="space-y-1">
            <Label for="check-out" class="text-xs">Check-Out</Label>
            <DatePicker v-model="checkOutDate" placeholder="Check-out date" />
          </div>
          <div class="space-y-1">
            <Label for="num-nights" class="text-xs">Nº of Nights</Label>
            <Input id="num-nights" v-model="numNights" placeholder="e.g. 3" />
          </div>
          <div class="space-y-1">
            <Label for="num-guests" class="text-xs">Nº of Guests</Label>
            <Input id="num-guests" v-model="numGuests" placeholder="e.g. 1" />
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
          <div class="space-y-1">
            <Label for="guest-names" class="text-xs">Guest Name(s)</Label>
            <Input
              id="guest-names"
              v-model="guestNames"
              placeholder="Name of guest(s)"
            />
          </div>
        </div>
      </div>

      <Separator />

      <!-- Payment -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Payment</span>
        <div class="flex items-center gap-6">
          <div class="flex items-center space-x-2">
            <Checkbox id="hotel-invoice" v-model="hasInvoice" />
            <Label for="hotel-invoice" class="text-sm">Invoice</Label>
          </div>
          <div class="flex items-center space-x-2">
            <Checkbox id="hotel-paid" v-model="isPaid" />
            <Label for="hotel-paid" class="text-sm">Paid</Label>
          </div>
        </div>
      </div>

      <Separator />

      <!-- Observations & Notes -->
      <div class="space-y-2">
        <Label for="hotel-notes" class="text-sm font-medium">
          Observations & Notes
        </Label>
        <Textarea
          id="hotel-notes"
          v-model="hotelNotes"
          placeholder="Any observations or notes"
          :rows="3"
        />
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
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Separator } from "@/components/ui/separator";
import { DatePicker } from "@/components/ui/date-picker";
import { Hotel } from "lucide-vue-next";

interface Props {
  entityId: string;
  stepNumber?: number;
  isLast?: boolean;
}

withDefaults(defineProps<Props>(), {
  stepNumber: 6,
  isLast: false,
});

// Request status
const hasRequestedHotelInfo = ref<boolean>(false);

// Hotel details
const hotelName = ref<string>("");
const roomType = ref<string>("");
const hotelPrice = ref<string>("");

// Booking
const checkInDate = ref<Date | null>(null);
const checkOutDate = ref<Date | null>(null);
const numNights = ref<string>("");
const numGuests = ref<string>("");
const guestNames = ref<string>("");

// Payment
const hasInvoice = ref<boolean>(false);
const isPaid = ref<boolean>(false);

// Notes
const hotelNotes = ref<string>("");

const isComplete = computed(() => {
  return (
    !!hotelName.value.trim() &&
    checkInDate.value !== null &&
    checkOutDate.value !== null &&
    isPaid.value === true
  );
});

defineExpose({
  isComplete,
});
</script>
