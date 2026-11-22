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
        <button
          type="button"
          class="text-xs text-muted-foreground"
          aria-label="Dismiss notification"
          @click="dismiss(t.id)"
        >
          ×
        </button>
      </div>
      <div v-if="t.description" class="text-sm text-muted-foreground mt-1">
        {{ t.description }}
      </div>
      <button
        v-if="t.action"
        type="button"
        class="mt-2 self-start text-sm font-medium underline underline-offset-2 hover:opacity-75 focus-visible:outline-offset-2"
        @click="handleAction(t.id, t.action?.onClick)"
      >
        {{ t.action.label }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import useToast from "@/lib/toast";

const { toasts, dismiss } = useToast();

const handleAction = (id: number, onClick?: () => void) => {
  onClick?.();
  dismiss(id);
};

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
