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
import { computed, ref, watch } from "vue";
import { useQuery } from "@pinia/colada";
import { getAllMembers, getMemberRole } from "@/api/members";
import type { TeamRole } from "@/dto/teams";
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
  roleFilter?: TeamRole; // Filter members by role
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

// Store member roles when filtering by role
const memberRoles = ref<Record<string, TeamRole>>({});
const loadingRoles = ref(false);

// Fetch roles for all members when roleFilter is provided
watch(
  () => [membersData.value, props.roleFilter] as const,
  async ([data, roleFilter]) => {
    if (!data?.data || !roleFilter) {
      memberRoles.value = {};
      return;
    }

    loadingRoles.value = true;
    const roles: Record<string, TeamRole> = {};

    try {
      await Promise.all(
        data.data.map(async (member) => {
          try {
            const response = await getMemberRole(member.id);
            if (response.data?.role) {
              roles[member.id] = response.data.role as TeamRole;
            }
          } catch {
            // Member might not have a role, skip
          }
        }),
      );
    } finally {
      memberRoles.value = roles;
      loadingRoles.value = false;
    }
  },
  { immediate: true },
);

const sortedMembers = computed(() => {
  if (!membersData.value?.data) return [];

  let members = membersData.value.data;

  // Filter by role if specified
  if (props.roleFilter && !loadingRoles.value) {
    members = members.filter(
      (member) => memberRoles.value[member.id] === props.roleFilter,
    );
  }

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
