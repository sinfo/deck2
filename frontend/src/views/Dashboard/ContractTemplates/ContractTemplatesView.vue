<script setup lang="ts">
import { ref, watch, onMounted } from "vue";
import { useEventStore } from "@/stores/event";
import { getTemplates } from "@/api/templates";
import UploadTemplateForm from "./UploadTemplateForm.vue";
import TemplatesList from "./TemplatesList.vue";
import { createDefaultTemplates } from "@/api/templates";

const eventStore = useEventStore();

interface Template {
  id: number | string;
  name?: string;
  url?: string;
}

const templatesForEvent = ref<Template[]>([]);
const allTemplates = ref<Template[]>([]);
const loading = ref(false);

async function loadTemplates() {
  loading.value = true;
  try {
    const ev = eventStore.selectedEvent;
    if (ev && ev.id) {
      const res = await getTemplates({ event: ev.id });
      templatesForEvent.value = res.data;
    } else {
      templatesForEvent.value = [];
    }

    // load all templates (for selecting which template record to upload to)
    const all = await getTemplates();
    allTemplates.value = all.data;
  } catch (err) {
    console.error(err);
  } finally {
    loading.value = false;
  }
}

watch(
  () => eventStore.selectedEvent,
  () => {
    loadTemplates();
  },
  { immediate: true },
);

onMounted(() => {
  loadTemplates();
});

function onUploaded() {
  loadTemplates();
}

const createDefaults = async () => {
  const ev = eventStore.selectedEvent;
  if (!ev || !ev.id) return alert("Select an event/edition first");
  try {
    await createDefaultTemplates(ev.id);
    await loadTemplates();
    alert("Created default Company Contract templates (EN/PT)");
  } catch (err: unknown) {
    console.error(err);
    const msg =
      (err as { response?: { data?: unknown } }).response?.data ||
      String(err) ||
      "Unable to create templates";
    alert(msg);
  }
};
</script>

<template>
  <div class="container mx-auto p-4">
    <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
      <div class="md:col-span-2">
        <TemplatesList :templates="templatesForEvent" />
      </div>
      <div>
        <div class="space-y-4">
          <UploadTemplateForm
            :event-id="eventStore.selectedEvent?.id ?? null"
            :templates="allTemplates"
            @uploaded="onUploaded"
          />

          <button
            class="w-full bg-blue-600 text-white px-3 py-2 rounded"
            @click="createDefaults"
          >
            Create default templates
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
