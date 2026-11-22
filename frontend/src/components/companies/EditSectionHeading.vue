<template>
  <div class="-mx-6 border-b-2 border-border">
    <h3 class="px-6 pb-2 text-sm font-semibold text-foreground">
      {{ title }}
    </h3>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  title: string;
}>();
</script>
