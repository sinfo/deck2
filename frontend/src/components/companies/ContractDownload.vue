<template>
  <div class="flex gap-2">
    <Button :disabled="isLoading" @click="download('pt')"
      >Generate Contract (PT)</Button
    >
    <Button :disabled="isLoading" @click="download('en')"
      >Generate Contract (EN)</Button
    >
  </div>
</template>

<script setup lang="ts">
import Button from "@/components/ui/button/Button.vue";
import { generateCompanyContract } from "@/api/companies";
import { useToast } from "@/lib/toast";
import { ref } from "vue";
import { useEventStore } from "@/stores/event";

const props = defineProps<{ companyId: string }>();

const { toast } = useToast();

const isLoading = ref(false);

const eventStore = useEventStore();

async function download(language: string) {
  isLoading.value = true;
  try {
    const eventId = eventStore.selectedEvent?.id;
    if (!eventId) {
      toast.error({
        title: "Error",
        description: "Select an event before generating the contract",
      });
      return;
    }

    const payload = {
      language: String(language).toLowerCase(),
      eventId,
    };

    const res = await generateCompanyContract(props.companyId, payload);
    // res is an Axios response with blob data in res.data
    const blob = new Blob([res.data], {
      type:
        res.headers["content-type"] ||
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    // try to use filename from header, fallback to generated name
    const cd = res.headers["content-disposition"];
    let filename = `contract-${props.companyId}.docx`;
    if (cd) {
      const m =
        /filename\*=UTF-8''(.+)$/.exec(cd) || /filename="?([^";]+)"?/.exec(cd);
      if (m && m[1]) filename = decodeURIComponent(m[1]);
    }
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(url);
    toast.success({
      title: "Download started",
      description: `Contract (${language.toUpperCase()}) is downloading`,
    });
  } catch (err: unknown) {
    console.error("Download contract failed", err);
    let message = "Unable to download contract";
    if (err) {
      const maybeErr = err as Error & { response?: { data?: unknown } };
      const data = maybeErr?.response?.data;
      // Axios returns a Blob for non-2xx responses when responseType is 'blob'.
      // If we received a Blob, try to read it as text and parse JSON.
      if (data && typeof (data as Blob).text === "function") {
        try {
          const text = await (data as Blob).text();
          try {
            const parsed = JSON.parse(text);
            message =
              (parsed as { message?: string })?.message || text || message;
          } catch {
            message = text || message;
          }
        } catch {
          // ignore read errors and fall back
        }
      } else if (data && typeof data === "object") {
        const obj = data as { message?: string };
        message = obj?.message || maybeErr.message || message;
      } else {
        message = maybeErr.message || message;
      }
    }
    toast.error({ title: "Error", description: String(message) });
  } finally {
    isLoading.value = false;
  }
}
</script>
