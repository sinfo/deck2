<template>
  <AlertDialog v-model:open="open">
    <AlertDialogContent
      class="flex max-h-[85vh] max-w-2xl flex-col overflow-hidden"
    >
      <AlertDialogHeader>
        <AlertDialogTitle>Gmail sync details</AlertDialogTitle>
        <AlertDialogDescription>
          Review the issues below, then try syncing again.
        </AlertDialogDescription>
      </AlertDialogHeader>

      <div class="min-h-0 overflow-y-auto">
        <table class="w-full border-separate border-spacing-y-2">
          <tbody>
            <tr v-for="issue in issues" :key="issue.id">
              <td
                class="rounded-lg border border-red-200 bg-red-50 p-1 dark:border-red-900/60 dark:bg-red-950/30"
              >
                <div class="rounded-md bg-card p-3">
                  <div class="flex items-center justify-between gap-3">
                    <p class="min-w-0 break-words text-sm font-semibold">
                      {{ issue.name }}
                    </p>
                    <span
                      v-if="issue.type"
                      class="shrink-0 text-xs text-red-700 dark:text-red-300"
                    >
                      {{ issue.type }}
                    </span>
                  </div>
                  <p class="mt-1 text-sm text-muted-foreground">
                    {{ readableReason(issue.reason) }}
                  </p>
                  <details class="mt-2 text-xs text-muted-foreground">
                    <summary class="cursor-pointer font-medium hover:underline">
                      More details
                    </summary>
                    <p class="mt-2 break-words font-mono">
                      {{ issue.reason }}
                    </p>
                    <p v-if="issue.entityId" class="mt-1 break-all">
                      Entity ID: {{ issue.entityId }}
                    </p>
                  </details>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <AlertDialogFooter>
        <AlertDialogCancel>Close</AlertDialogCancel>
      </AlertDialogFooter>
    </AlertDialogContent>
  </AlertDialog>
</template>

<script setup lang="ts">
import { computed } from "vue";
import type { EntityLinkResult } from "@/composables/gmailSync/common";
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

const open = defineModel<boolean>("open", { default: false });
const props = defineProps<{
  failures: EntityLinkResult[];
  generalError: string | null;
}>();

const issues = computed(() => [
  ...(props.generalError
    ? [
        {
          id: "sync",
          name: "Gmail sync",
          type: "",
          reason: props.generalError,
          entityId: "",
        },
      ]
    : []),
  ...props.failures.map((failure) => ({
    id: `${failure.entityType}:${failure.entityId}`,
    name: failure.entityName,
    type: failure.entityType === "company" ? "Company" : "Speaker",
    reason: failure.errorMessage || "No additional information was provided.",
    entityId: failure.entityId,
  })),
]);

const readableReason = (reason: string): string => {
  const error = reason.toLowerCase();
  if (
    /\b(401|403|unauthorized|forbidden)\b|permission|scope|token|authentication/.test(
      error,
    )
  ) {
    return "Gmail access was denied. Reconnect your Google account and try again.";
  }
  if (/\b429\b|rate limit|quota/.test(error)) {
    return "Gmail is temporarily limiting requests. Try again later.";
  }
  if (/saving gmail messages|linking gmail threads/.test(error)) {
    return "Deck couldn't save or link this conversation. Please try again.";
  }
  if (/fetching.*gmail|searching gmail/.test(error)) {
    return "Gmail couldn't load this conversation. Please try again.";
  }
  if (/network|timed?\s*out|\b5\d\d\b|failed to fetch/.test(error)) {
    return "A network or server issue interrupted the sync. Please try again.";
  }
  return "An error prevented this conversation from syncing. Please try again.";
};
</script>
