<script setup lang="ts">
import { ref } from "vue";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select";
import Input from "@/components/ui/input/Input.vue";
import { uploadTemplate } from "@/api/templates";

interface Template {
  id: number | string;
  name?: string;
}

const props = defineProps<{ eventId: number | null; templates: Template[] }>();

const emit = defineEmits<{ (e: "uploaded"): void }>();

const selectedTemplate = ref<string | number | null>(null);
const file = ref<File | null>(null);
const uploading = ref(false);

function onFileChange(e: Event) {
  const t = e.target as HTMLInputElement;
  if (t.files && t.files[0]) file.value = t.files[0];
}

async function submit() {
  if (!selectedTemplate.value)
    return alert("Choose a template record to upload to");
  if (!file.value) return alert("Choose a file to upload");
  const eventId = props.eventId;
  if (!eventId) return alert("Select an event/edition first");

  uploading.value = true;
  try {
    await uploadTemplate(String(selectedTemplate.value), eventId, file.value);
    emit("uploaded");
  } catch (err: unknown) {
    console.error(err);
    const msg =
      (err as { response?: { data?: unknown } }).response?.data ||
      String(err) ||
      "Upload failed";
    alert(msg);
  } finally {
    uploading.value = false;
  }
}
</script>

<template>
  <div class="p-4 bg-white rounded border">
    <h3 class="text-lg font-semibold mb-2">Upload Template File</h3>

    <div class="mb-2">
      <label class="block text-sm text-gray-600">Template record</label>
      <Select v-model="selectedTemplate" :disabled="!props.eventId">
        <SelectTrigger class="mt-1 w-full border rounded px-2 py-1">
          <SelectValue placeholder="-- select template --" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem v-for="t in props.templates" :key="t.id" :value="t.id">
            {{ t.name }}
          </SelectItem>
        </SelectContent>
      </Select>
    </div>

    <div class="mb-2">
      <label class="block text-sm text-gray-600">File (.docx)</label>
      <Input
        type="file"
        accept=".docx,application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        @change="onFileChange"
      />
    </div>

    <div class="flex items-center gap-2">
      <Button :disabled="uploading" @click="submit">Upload</Button>
      <span v-if="uploading">Uploading...</span>
    </div>
  </div>
</template>
