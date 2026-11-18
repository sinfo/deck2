<template>
  <div class="space-y-1">
    <div class="flex items-center gap-2">
      <span
        class="flex size-6 flex-shrink-0 items-center justify-center rounded-md border bg-muted/60 text-muted-foreground"
      >
        <component :is="icon" class="size-3.5" />
      </span>
      <h3
        class="whitespace-nowrap text-xs font-semibold uppercase tracking-wider text-muted-foreground"
      >
        {{ title }}
      </h3>
      <span class="h-px flex-1 bg-border" />
    </div>
    <p v-if="description" class="pl-8 text-xs text-muted-foreground">
      {{ description }}
    </p>
  </div>
</template>

<script setup lang="ts">
import type { Component } from "vue";

defineProps<{
  title: string;
  icon: Component;
  description?: string;
}>();
</script>
