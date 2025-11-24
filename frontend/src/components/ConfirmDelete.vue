<template>
  <div class="space-y-3">
    <div>
      <h4 class="font-medium text-sm">{{ props.title }}</h4>
      <p class="text-sm text-muted-foreground mt-1">{{ props.message }}</p>
    </div>
    <div class="flex justify-end gap-2">
      <Button variant="outline" size="sm" @click="emit('cancel')">
        {{ props.cancelLabel }}
      </Button>
      <Button
        variant="destructive"
        size="sm"
        :disabled="props.isDeleting"
        @click="emit('confirm')"
      >
        {{ props.isDeleting ? props.deletingLabel : props.confirmLabel }}
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import Button from "@/components/ui/button/Button.vue";

const props = defineProps({
  title: { type: String, default: "Confirm deletion" },
  message: {
    type: String,
    default:
      "Are you sure you want to delete this item? This action cannot be undone.",
  },
  isDeleting: { type: Boolean, default: false },
  confirmLabel: { type: String, default: "Delete" },
  deletingLabel: { type: String, default: "Deleting..." },
  cancelLabel: { type: String, default: "Cancel" },
});

const emit = defineEmits(["confirm", "cancel"]);

// use props directly in the template
</script>
