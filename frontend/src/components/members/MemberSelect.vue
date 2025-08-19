<template>
  <div class="relative">
    <Label v-if="label" :for="inputId" class="text-sm font-medium">
      {{ label }}
    </Label>
    <Select
      :model-value="modelValue"
      @update:model-value="
        (value) => value && $emit('update:modelValue', value as string)
      "
    >
      <SelectTrigger :id="inputId" class="w-full">
        <div v-if="selectedMember" class="flex items-center gap-2">
          <Image
            :src="selectedMember.img"
            :alt="selectedMember.name"
            class="w-6 h-6 rounded-full object-cover border"
          />
          <span>{{ selectedMember.name }}</span>
        </div>
        <SelectValue
          v-else
          :placeholder="placeholder || 'Select a member...'"
        />
      </SelectTrigger>
      <SelectContent>
        <div class="max-h-64 overflow-y-auto">
          <SelectItem
            v-for="member in sortedMembers"
            :key="member.id"
            :value="member.id"
            class="flex items-center gap-2 px-3 py-2"
          >
            <Image
              :src="member.img"
              :alt="member.name"
              class="w-6 h-6 rounded-full object-cover border"
            />
            <span>{{ member.name }}</span>
          </SelectItem>
          <div
            v-if="sortedMembers.length === 0"
            class="px-3 py-2 text-sm text-muted-foreground"
          >
            No members found
          </div>
        </div>
      </SelectContent>
    </Select>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useQuery } from "@pinia/colada";
import { getAllMembers } from "@/api/members";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import Image from "../Image.vue";

interface Props {
  modelValue?: string;
  label?: string;
  placeholder?: string;
  disabled?: boolean;
  eventId?: number;
}

const props = defineProps<Props>();

defineEmits<{
  "update:modelValue": [value: string];
}>();

const inputId = `member-select-${Math.random().toString(36).substr(2, 9)}`;

const { data: membersData } = useQuery({
  key: () => ["members", `${props.eventId}`],
  query: () => getAllMembers({ event: props.eventId }),
});

const sortedMembers = computed(() => {
  if (!membersData.value?.data) return [];

  const members = membersData.value.data;
  return members.sort((a, b) =>
    a.name.localeCompare(b.name, undefined, { sensitivity: "base" }),
  );
});

const selectedMember = computed(() => {
  if (!membersData.value?.data || !props.modelValue) return null;
  return (
    membersData.value.data.find((member) => member.id === props.modelValue) ||
    null
  );
});
</script>
