<template>
  <div class="-mx-6" :class="{ 'border-t-2 border-border pt-5': divider }">
    <h3 class="px-6 text-base font-bold tracking-tight text-foreground">
      {{ title }}
    </h3>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  title: string;
  divider?: boolean;
}>();
</script>
