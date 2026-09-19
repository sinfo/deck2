<template>
  <AlertDialog v-model:open="isOpen">
    <AlertDialogContent class="max-w-3xl max-h-[85vh] flex flex-col">
      <AlertDialogHeader class="flex-shrink-0">
        <AlertDialogTitle class="flex items-center gap-2 text-xl">
          <Zap class="w-5 h-5 text-primary" />
          Automatic Gmail Thread Linker
        </AlertDialogTitle>
        <AlertDialogDescription>
          Automatically search and link Gmail threads for all companies and
          speakers in the selected edition.
        </AlertDialogDescription>
      </AlertDialogHeader>

      <div class="flex-1 overflow-hidden flex flex-col py-4 gap-4">
        <!-- 1. Google Authentication Required -->
        <div
          v-if="!authStore.isGoogleAuthenticated"
          class="flex-1 flex flex-col items-center justify-center gap-4 py-8 text-center"
        >
          <div
            class="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center text-primary mb-2"
          >
            <Mail class="w-6 h-6" />
          </div>
          <div class="max-w-md">
            <h3 class="text-base font-semibold mb-1">
              One-Time Gmail Connection
            </h3>
            <p class="text-sm text-muted-foreground">
              Connect your Google account to allow DECK to scan your inbox and
              automatically link relevant threads to company and speaker
              communications.
            </p>
          </div>
          <Button :disabled="isSigningIn" @click="handleSignIn">
            {{ isSigningIn ? "Connecting..." : "Connect to Google & Start" }}
          </Button>
        </div>

        <!-- 2. Idle State - Ready to Start -->
        <div
          v-else-if="!isAutoLinking && results.length === 0"
          class="flex-1 flex flex-col items-center justify-center gap-4 py-8 text-center"
        >
          <div
            class="w-12 h-12 rounded-full bg-blue-500/10 flex items-center justify-center text-blue-500 mb-2"
          >
            <Sparkles class="w-6 h-6" />
          </div>
          <div class="max-w-md">
            <h3 class="text-base font-semibold mb-1">
              Auto-Link Event Communications
            </h3>
            <p class="text-sm text-muted-foreground">
              This will search your Gmail for emails matching company
              representatives and speaker contacts for the current event
              edition, linking matching threads automatically.
            </p>
          </div>
          <Button class="gap-2" @click="startAutoLink">
            <Zap class="w-4 h-4" />
            Start Auto-Linking
          </Button>
        </div>

        <!-- 3. In Progress State -->
        <div
          v-else-if="isAutoLinking"
          class="flex-1 flex flex-col items-center justify-center gap-6 py-8"
        >
          <div class="w-full max-w-md space-y-3 text-center">
            <div class="flex items-center justify-center gap-2 font-medium">
              <RefreshCw class="w-5 h-5 animate-spin text-primary" />
              <span>Scanning Inbox & Linking Entities...</span>
            </div>
            <Progress :model-value="progressPercent" class="h-2.5 w-full" />
            <div
              class="text-xs text-muted-foreground flex justify-between items-center px-1"
            >
              <span class="truncate max-w-[280px]">
                Processing:
                <strong class="text-foreground">{{
                  currentProcessingEntity || "Starting..."
                }}</strong>
              </span>
              <span class="font-mono font-medium">{{ progressPercent }}%</span>
            </div>
          </div>
        </div>

        <!-- 4. Results & Summary View -->
        <div v-else class="flex-1 overflow-hidden flex flex-col gap-4">
          <!-- Summary Header Stats -->
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 flex-shrink-0">
            <div
              class="p-3 rounded-lg border bg-emerald-50/50 dark:bg-emerald-950/20 border-emerald-200 dark:border-emerald-900"
            >
              <div
                class="text-xs text-emerald-700 dark:text-emerald-400 font-medium"
              >
                Auto-Linked
              </div>
              <div
                class="text-2xl font-bold text-emerald-800 dark:text-emerald-300"
              >
                {{ successCount }}
              </div>
            </div>
            <div
              class="p-3 rounded-lg border bg-blue-50/50 dark:bg-blue-950/20 border-blue-200 dark:border-blue-900"
            >
              <div class="text-xs text-blue-700 dark:text-blue-400 font-medium">
                Already Linked
              </div>
              <div class="text-2xl font-bold text-blue-800 dark:text-blue-300">
                {{ alreadyLinkedCount }}
              </div>
            </div>
            <div
              class="p-3 rounded-lg border bg-amber-50/50 dark:bg-amber-950/20 border-amber-200 dark:border-amber-900"
            >
              <div
                class="text-xs text-amber-700 dark:text-amber-400 font-medium"
              >
                Not Found
              </div>
              <div
                class="text-2xl font-bold text-amber-800 dark:text-amber-300"
              >
                {{ notFoundCount }}
              </div>
            </div>
            <div
              class="p-3 rounded-lg border bg-red-50/50 dark:bg-red-950/20 border-red-200 dark:border-red-900"
            >
              <div class="text-xs text-red-700 dark:text-red-400 font-medium">
                Errors
              </div>
              <div class="text-2xl font-bold text-red-800 dark:text-red-300">
                {{ errorCount }}
              </div>
            </div>
          </div>

          <!-- Filter Tabs -->
          <div
            class="flex items-center justify-between border-b pb-2 flex-shrink-0"
          >
            <div class="flex gap-1">
              <Button
                size="sm"
                :variant="activeTab === 'action_required' ? 'default' : 'ghost'"
                class="text-xs h-8"
                @click="activeTab = 'action_required'"
              >
                Action Required ({{ actionRequiredCount }})
              </Button>
              <Button
                size="sm"
                :variant="activeTab === 'all' ? 'default' : 'ghost'"
                class="text-xs h-8"
                @click="activeTab = 'all'"
              >
                All Entities ({{ results.length }})
              </Button>
            </div>
            <Button
              size="sm"
              variant="outline"
              class="text-xs h-8 gap-1"
              @click="reRunAutoLink"
            >
              <RefreshCw class="w-3.5 h-3.5" />
              Re-Scan
            </Button>
          </div>

          <!-- Results Entity List -->
          <div class="flex-1 overflow-y-auto space-y-2 pr-1">
            <div
              v-if="filteredResults.length === 0"
              class="py-8 text-center text-sm text-muted-foreground"
            >
              <CheckCircle2
                v-if="activeTab === 'action_required'"
                class="w-8 h-8 text-emerald-500 mx-auto mb-2 opacity-80"
              />
              <span v-if="activeTab === 'action_required'">
                All entities have linked Gmail threads! No manual action
                required.
              </span>
              <span v-else>No entities found for this filter.</span>
            </div>

            <div
              v-for="item in filteredResults"
              :key="item.entityId"
              class="p-3 rounded-lg border flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-card hover:bg-muted/40 transition-colors"
            >
              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2 mb-1">
                  <span class="font-medium text-sm truncate">{{
                    item.entityName
                  }}</span>
                  <Badge
                    variant="outline"
                    class="text-[10px] capitalize px-1.5 py-0"
                  >
                    {{ item.entityType }}
                  </Badge>
                </div>
                <div
                  class="flex items-center gap-2 text-xs text-muted-foreground"
                >
                  <span
                    >Query:
                    <code class="bg-muted px-1 py-0.5 rounded text-[11px]">{{
                      item.searchQueryUsed
                    }}</code></span
                  >
                </div>
                <div
                  v-if="item.errorMessage"
                  class="text-xs text-destructive mt-1"
                >
                  {{ item.errorMessage }}
                </div>
              </div>

              <!-- Status badge & Manual link trigger -->
              <div class="flex items-center gap-2 flex-shrink-0">
                <!-- Status Badge -->
                <Badge
                  :class="getStatusBadgeClasses(item.status)"
                  class="text-xs font-normal"
                >
                  <span v-if="item.status === 'SUCCESS'">
                    Linked {{ item.linkedThreadsCount }} thread(s)
                  </span>
                  <span v-else-if="item.status === 'ALREADY_LINKED'">
                    {{ item.linkedThreadsCount }} thread(s) linked
                  </span>
                  <span v-else-if="item.status === 'MANUALLY_LINKED'">
                    Manually linked ({{ item.linkedThreadsCount }})
                  </span>
                  <span v-else-if="item.status === 'NOT_FOUND'">
                    No threads found
                  </span>
                  <span v-else-if="item.status === 'ERROR'"> Failed </span>
                </Badge>

                <!-- Link Manually Button -->
                <Button
                  size="sm"
                  variant="outline"
                  class="text-xs h-8 gap-1"
                  @click="openManualPicker(item)"
                >
                  <LinkIcon class="w-3.5 h-3.5" />
                  Link Manually
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <AlertDialogFooter class="flex-shrink-0 pt-2 border-t">
        <AlertDialogCancel @click="closeModal">
          {{ results.length > 0 ? "Done" : "Cancel" }}
        </AlertDialogCancel>
      </AlertDialogFooter>
    </AlertDialogContent>
  </AlertDialog>

  <!-- Nested Gmail Thread Picker for Manual Fallback -->
  <GmailThreadPicker
    v-if="manualPickerEntity"
    v-model:open="isManualPickerOpen"
    :initial-thread-ids="manualPickerEntity.threadIds"
    :default-search-query="
      manualPickerEntity.searchQueryUsed || manualPickerEntity.entityName
    "
    @save="handleManualPickerSave"
  />
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogCancel,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import {
  Zap,
  Mail,
  RefreshCw,
  Sparkles,
  CheckCircle2,
  Link as LinkIcon,
} from "lucide-vue-next";
import { useAuthStore } from "@/stores/auth";
import { useGoogleAuth } from "@/composables/useGoogleAuth";
import { useEventStore } from "@/stores/event";
import {
  useAutoLinkGmail,
  type EntityLinkResult,
  type EntityAutoLinkStatus,
} from "@/composables/useAutoLinkGmail";
import { updateCompanyGmailThreadIds } from "@/api/companies";
import { updateSpeakerGmailThreadIds } from "@/api/speakers";
import GmailThreadPicker from "./GmailThreadPicker.vue";

const props = defineProps<{
  open: boolean;
  eventId?: number;
}>();

const emit = defineEmits<{
  (e: "update:open", value: boolean): void;
  (e: "complete"): void;
}>();

const authStore = useAuthStore();
const eventStore = useEventStore();
const { signInWithGoogle, isSigningIn } = useGoogleAuth();
const {
  isAutoLinking,
  progressPercent,
  currentProcessingEntity,
  results,
  autoLinkEventEntities,
  markAsManuallyLinked,
} = useAutoLinkGmail();

const activeTab = ref<"action_required" | "all">("action_required");

// State for manual picker fallback
const isManualPickerOpen = ref(false);
const manualPickerEntity = ref<EntityLinkResult | null>(null);

const isOpen = computed({
  get: () => props.open,
  set: (val) => emit("update:open", val),
});

const targetEventId = computed(() => {
  return props.eventId || eventStore.selectedEvent?.id || null;
});

const successCount = computed(
  () =>
    results.value.filter(
      (r) => r.status === "SUCCESS" || r.status === "MANUALLY_LINKED",
    ).length,
);

const alreadyLinkedCount = computed(
  () => results.value.filter((r) => r.status === "ALREADY_LINKED").length,
);

const notFoundCount = computed(
  () => results.value.filter((r) => r.status === "NOT_FOUND").length,
);

const errorCount = computed(
  () => results.value.filter((r) => r.status === "ERROR").length,
);

const actionRequiredCount = computed(
  () => notFoundCount.value + errorCount.value,
);

const filteredResults = computed(() => {
  if (activeTab.value === "action_required") {
    return results.value.filter(
      (r) => r.status === "NOT_FOUND" || r.status === "ERROR",
    );
  }
  return results.value;
});

const handleSignIn = async () => {
  const success = await signInWithGoogle();
  if (success) {
    startAutoLink();
  }
};

const startAutoLink = async () => {
  if (!targetEventId.value) return;
  await autoLinkEventEntities(targetEventId.value);
};

const reRunAutoLink = async () => {
  if (!targetEventId.value) return;
  await autoLinkEventEntities(targetEventId.value, { forceReScan: true });
};

const getStatusBadgeClasses = (status: EntityAutoLinkStatus): string => {
  switch (status) {
    case "SUCCESS":
    case "MANUALLY_LINKED":
      return "bg-emerald-100 text-emerald-800 border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-300";
    case "ALREADY_LINKED":
      return "bg-blue-100 text-blue-800 border-blue-200 dark:bg-blue-950/40 dark:text-blue-300";
    case "NOT_FOUND":
      return "bg-amber-100 text-amber-800 border-amber-200 dark:bg-amber-950/40 dark:text-amber-300";
    case "ERROR":
      return "bg-red-100 text-red-800 border-red-200 dark:bg-red-950/40 dark:text-red-300";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

const openManualPicker = (item: EntityLinkResult) => {
  manualPickerEntity.value = item;
  isManualPickerOpen.value = true;
};

const handleManualPickerSave = async (threadIds: string[]) => {
  if (!manualPickerEntity.value) return;

  const entity = manualPickerEntity.value;
  try {
    if (entity.entityType === "company") {
      await updateCompanyGmailThreadIds(entity.entityId, threadIds);
    } else {
      await updateSpeakerGmailThreadIds(entity.entityId, threadIds);
    }

    markAsManuallyLinked(entity.entityId, threadIds);
  } catch (err) {
    console.error("Failed to update thread IDs manually:", err);
  } finally {
    manualPickerEntity.value = null;
  }
};

const closeModal = () => {
  if (results.value.length > 0) {
    emit("complete");
  }
  isOpen.value = false;
};

watch(
  () => props.open,
  (newVal) => {
    if (newVal) {
      if (
        results.value.length === 0 &&
        authStore.isGoogleAuthenticated &&
        targetEventId.value
      ) {
        startAutoLink();
      }
    }
  },
);
</script>
