<template>
  <div class="flex items-center">
    <Image :src="member.img" alt="Member Avatar" class="w-12 h-12 rounded-xl" />

    <div class="w-full flex flex-col gap-2">
      <span class="ml-2">{{ member.name }}</span>

      <Separator v-if="withSeparator" class="mx-2 h-6 bg-gray-300" />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Member } from "@/dto/members";
import Image from "../Image.vue";
import Separator from "../ui/separator/Separator.vue";

defineProps<{
  member: Member;
  withSeparator?: boolean;
}>();
</script>
