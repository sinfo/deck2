<template>
  <div
    class="relative text-center text-muted-foreground py-8 border border-dashed rounded-lg hover:border-primary/50 hover:bg-muted/50 transition-colors"
    :class="
      disabled
        ? 'opacity-50 cursor-not-allowed'
        : loading
          ? 'cursor-not-allowed'
          : 'cursor-pointer'
    "
    @click="!disabled && !loading && $emit('click')"
  >
    <!-- Loading overlay -->
    <div
      v-if="loading"
      class="absolute inset-0 flex flex-col items-center justify-center bg-background/80 backdrop-blur-sm rounded-lg"
    >
      <div class="flex items-center gap-3">
        <div
          class="w-5 h-5 border-2 border-primary border-t-transparent rounded-full animate-spin"
        ></div>
        <div class="text-sm font-medium">
          {{ loadingText || "Loading..." }}
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="space-y-2" :class="loading ? 'pointer-events-none' : ''">
      <div class="text-sm font-medium">
        {{ title }}
      </div>
      <div v-if="description" class="text-xs">
        {{ description }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  title: string;
  description?: string;
  disabled?: boolean;
  loading?: boolean;
  loadingText?: string;
}

defineProps<Props>();

defineEmits<{
  click: [];
}>();
</script>
