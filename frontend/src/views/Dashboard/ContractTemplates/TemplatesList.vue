<script setup lang="ts">
import { Button } from "@/components/ui/button";
import { downloadTemplate } from "@/api/templates";

interface Template {
  id: number | string;
  name?: string;
  url?: string;
}

defineProps<{ templates: Template[] }>();

async function download(t: Template) {
  try {
    const res = await downloadTemplate(String(t.id));
    const url = window.URL.createObjectURL(res.data);
    const a = document.createElement("a");
    a.href = url;
    a.download = t.name || "template.docx";
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(url);
  } catch (err: unknown) {
    console.error(err);
    const msg =
      (err as { response?: { data?: unknown } }).response?.data ||
      String(err) ||
      "Download failed";
    alert(msg);
  }
}
</script>

<template>
  <div class="p-4 bg-white rounded border">
    <h3 class="text-lg font-semibold mb-2">Templates for this edition</h3>
    <div v-if="templates.length === 0" class="text-sm text-gray-500">
      No templates for this edition.
    </div>
    <table v-else class="w-full table-auto">
      <thead>
        <tr class="text-left text-sm text-gray-600">
          <th class="py-1">Name</th>
          <th class="py-1">Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="t in templates" :key="t.id" class="border-t">
          <td class="py-2">{{ t.name }}</td>
          <td class="py-2">
            <Button size="sm" @click.prevent="download(t)">Download</Button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
