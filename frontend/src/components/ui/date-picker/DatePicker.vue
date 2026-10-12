<script setup lang="ts">
import type { HTMLAttributes } from "vue";
import { computed, ref, watch } from "vue";
import {
  CalendarDate,
  CalendarDateTime,
  getLocalTimeZone,
  today,
} from "@internationalized/date";
import { useVModel } from "@vueuse/core";
import { CalendarIcon, Loader2 } from "lucide-vue-next";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Input } from "@/components/ui/input";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { cn } from "@/lib/utils";

interface Props {
  modelValue?: Date | null;
  placeholder?: string;
  loading?: boolean;
  disabled?: boolean;
  showTime?: boolean;
  class?: HTMLAttributes["class"];
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: null,
  placeholder: "Pick a date",
  loading: false,
  disabled: false,
  showTime: false,
  class: "",
});

const emit = defineEmits<{
  "update:modelValue": [value: Date | null];
}>();

const modelValue = useVModel(props, "modelValue", emit, {
  passive: true,
  defaultValue: null,
});

const isOpen = ref(false);

// Convert Date to CalendarDate/CalendarDateTime for the Calendar component
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const calendarValue = ref<any>(null);

const updateCalendarValue = () => {
  if (!modelValue.value) {
    calendarValue.value = null;
    return;
  }
  const d = modelValue.value;
  if (props.showTime) {
    calendarValue.value = new CalendarDateTime(
      d.getFullYear(),
      d.getMonth() + 1,
      d.getDate(),
      d.getHours(),
      d.getMinutes(),
    );
  } else {
    calendarValue.value = new CalendarDate(
      d.getFullYear(),
      d.getMonth() + 1,
      d.getDate(),
    );
  }
};

// Initialize calendar value
updateCalendarValue();

// Watch for external modelValue changes
watch(
  () => modelValue.value,
  () => updateCalendarValue(),
);

// Time inputs
const hours = ref(
  modelValue.value?.getHours().toString().padStart(2, "0") ?? "00",
);
const minutes = ref(
  modelValue.value?.getMinutes().toString().padStart(2, "0") ?? "00",
);

// Update time when modelValue changes externally
watch(
  () => modelValue.value,
  (newVal) => {
    if (newVal) {
      hours.value = newVal.getHours().toString().padStart(2, "0");
      minutes.value = newVal.getMinutes().toString().padStart(2, "0");
    }
  },
);

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const onCalendarChange = (value: any) => {
  if (!value) {
    modelValue.value = null;
    return;
  }
  const dateVal = Array.isArray(value) ? value[0] : value;
  if (!dateVal) {
    modelValue.value = null;
    return;
  }

  if (props.showTime) {
    const h = parseInt(hours.value) || 0;
    const m = parseInt(minutes.value) || 0;
    const newDate = new Date(
      dateVal.year,
      dateVal.month - 1,
      dateVal.day,
      h,
      m,
    );
    modelValue.value = newDate;
  } else {
    const newDate = dateVal.toDate(getLocalTimeZone());
    modelValue.value = newDate;
    isOpen.value = false;
  }
};

const onTimeChange = () => {
  if (!modelValue.value) return;

  const h = Math.max(0, Math.min(23, parseInt(hours.value) || 0));
  const m = Math.max(0, Math.min(59, parseInt(minutes.value) || 0));

  hours.value = h.toString().padStart(2, "0");
  minutes.value = m.toString().padStart(2, "0");

  const newDate = new Date(modelValue.value);
  newDate.setHours(h, m);
  modelValue.value = newDate;
};

const displayValue = computed(() => {
  if (!modelValue.value) return "";
  const d = modelValue.value;

  const dateStr = d.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  if (props.showTime) {
    const timeStr = d.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
    return `${dateStr} ${timeStr}`;
  }

  return dateStr;
});

const defaultPlaceholder = today(getLocalTimeZone());
</script>

<template>
  <Popover v-model:open="isOpen">
    <PopoverTrigger as-child>
      <Button
        variant="outline"
        :disabled="props.disabled || props.loading"
        :class="
          cn(
            'w-full justify-start text-left font-normal',
            !modelValue && 'text-muted-foreground',
            props.class,
          )
        "
      >
        <Loader2 v-if="props.loading" class="mr-2 h-4 w-4 animate-spin" />
        <CalendarIcon v-else class="mr-2 h-4 w-4" />
        {{ displayValue || placeholder }}
      </Button>
    </PopoverTrigger>
    <PopoverContent class="w-auto p-0" align="start">
      <Calendar
        v-model="calendarValue"
        :initial-focus="true"
        :default-placeholder="defaultPlaceholder"
        layout="month-and-year"
        @update:model-value="onCalendarChange"
      />
      <div v-if="showTime" class="border-t p-3">
        <div class="flex items-center gap-2">
          <span class="text-sm text-muted-foreground">Time:</span>
          <Input
            v-model="hours"
            type="text"
            inputmode="numeric"
            maxlength="2"
            class="w-14 text-center"
            placeholder="HH"
            @blur="onTimeChange"
            @keyup.enter="onTimeChange"
          />
          <span class="text-muted-foreground">:</span>
          <Input
            v-model="minutes"
            type="text"
            inputmode="numeric"
            maxlength="2"
            class="w-14 text-center"
            placeholder="MM"
            @blur="onTimeChange"
            @keyup.enter="onTimeChange"
          />
        </div>
      </div>
    </PopoverContent>
  </Popover>
</template>
