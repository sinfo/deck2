<template>
  <Popover v-model:open="isPopoverOpen">
    <PopoverTrigger as-child>
      <Badge
        :variant="modelValue ? 'default' : 'outline'"
        class="cursor-pointer hover:opacity-80 transition-opacity"
      >
        {{ modelValue ? activeLabel : inactiveLabel }}
      </Badge>
    </PopoverTrigger>
    <PopoverContent class="w-auto p-3">
      <div class="grid gap-3" style="grid-template-columns: min-content">
        <p class="text-sm font-medium whitespace-nowrap">Update status</p>
        <p class="text-xs text-muted-foreground">
          {{ description }}
        </p>
        <div class="flex gap-2 w-max">
          <Button size="sm" @click="setStatus(true)">
            {{ activeLabel }}
          </Button>
          <Button size="sm" variant="outline" @click="setStatus(false)">
            {{ inactiveLabel }}
          </Button>
        </div>
      </div>
    </PopoverContent>
  </Popover>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";

interface Props {
  modelValue: boolean;
  activeLabel?: string;
  inactiveLabel?: string;
  description?: string;
}

withDefaults(defineProps<Props>(), {
  activeLabel: "Requested",
  inactiveLabel: "Not Requested",
  description: "Update the status.",
});

const emit = defineEmits<{
  "update:modelValue": [value: boolean];
}>();

const isPopoverOpen = ref(false);

const setStatus = (value: boolean) => {
  emit("update:modelValue", value);
  isPopoverOpen.value = false;
};
</script>
