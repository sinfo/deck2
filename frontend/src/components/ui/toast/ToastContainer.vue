<template>
  <div class="fixed bottom-4 right-4 z-50 flex flex-col gap-2 items-end">
    <div
      v-for="t in toasts"
      :key="t.id"
      class="max-w-sm w-full rounded-md shadow-md p-3 border flex flex-col"
      :class="toastClass(t.type)"
    >
      <div class="flex items-start justify-between gap-2">
        <div class="font-medium">{{ t.title || t.type || "Info" }}</div>
        <button class="text-xs text-muted-foreground" @click="dismiss(t.id)">
          ×
        </button>
      </div>
      <div v-if="t.description" class="text-sm text-muted-foreground mt-1">
        {{ t.description }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import useToast from "@/lib/toast";

const { toasts, dismiss } = useToast();

const toastClass = (type?: string) => {
  switch (type) {
    case "success":
      return "bg-green-50 border-green-200";
    case "error":
      return "bg-red-50 border-red-200";
    case "warning":
      return "bg-yellow-50 border-yellow-200";
    default:
      return "bg-white border-border";
  }
};
</script>
