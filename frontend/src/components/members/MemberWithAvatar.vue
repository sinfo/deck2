<template>
  <div class="flex items-center">
    <Image :src="props.member.img" alt="Member Avatar" :class="avatarClass" />

    <div class="w-full flex items-center">
      <span :class="nameClass">{{ props.member.name }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import type { Member } from "@/dto/members";
import Image from "../Image.vue";

const props = defineProps<{
  member: Member;
  withSeparator?: boolean;
  /** 'sm' = compact, 'md' = default, 'lg' = larger */
  size?: "sm" | "md" | "lg";
}>();

const avatarClass = computed(() => {
  switch (props.size) {
    case "sm":
      return "w-6 h-6 rounded-full";
    case "lg":
      return "w-16 h-16 rounded-xl";
    default:
      return "w-12 h-12 rounded-xl";
  }
});

const nameClass = computed(() =>
  props.size === "sm" ? "ml-3 text-sm" : "ml-4",
);
</script>
