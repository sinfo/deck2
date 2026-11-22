<template>
  <div class="min-w-0 border-b pb-2">
    <h3 class="text-sm font-semibold text-foreground">
      {{ title }}
    </h3>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  title: string;
}>();
</script>
