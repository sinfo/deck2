<template>
  <div class="w-full max-w-md mx-auto p-4">
    <div class="mb-3">
      <h3 class="text-lg font-medium">Create Category</h3>
      <p class="text-sm text-muted-foreground">Add a new category for items.</p>
    </div>

    <div class="space-y-4">
      <div>
        <Label class="text-sm font-medium">Name *</Label>
        <Input v-model="name" :disabled="isLoading" autofocus />
        <span v-if="error" class="text-sm text-destructive">{{ error }}</span>
      </div>

      <div class="flex justify-end gap-2">
        <Button variant="outline" :disabled="isLoading" @click="$emit('cancel')"
          >Cancel</Button
        >
        <Button :disabled="isLoading" @click="handleCreate">Create</Button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createItemCategory } from "@/api/items";

const emit = defineEmits<{ cancel: []; success: [name: string] }>();

const name = ref("");
const isLoading = ref(false);
const error = ref("");

const handleCreate = async () => {
  error.value = "";
  if (!name.value || !name.value.trim()) {
    error.value = "Name is required";
    return;
  }
  isLoading.value = true;
  try {
    await createItemCategory(name.value.trim());
    emit("success", name.value.trim());
  } catch (err) {
    console.error("Failed to create category", err);
    error.value = "Failed to create category";
  } finally {
    isLoading.value = false;
  }
};
</script>
