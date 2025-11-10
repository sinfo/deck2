<template>
  <div class="flex items-center">
    <Image :src="member.img" alt="Member Avatar" class="w-12 h-12 rounded-xl" />

    <div class="w-full flex items-center">
      <span class="ml-4">{{ member.name }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Member } from "@/dto/members";
import Image from "../Image.vue";

defineProps<{
  member: Member;
  withSeparator?: boolean;
}>();
</script>
