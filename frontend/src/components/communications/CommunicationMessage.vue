<template>
  <div
    :class="[
      'flex gap-2',
      thread.kind === ThreadKind.ThreadKindPhoneCall
        ? 'justify-center'
        : getMessageDirection(thread.kind) === 'outgoing'
          ? 'justify-end'
          : 'justify-start',
    ]"
  >
    <!-- Author avatar for messages (including phone calls) -->
    <div class="flex flex-col items-center gap-1">
      <Image
        v-if="getAuthorAvatar(getMessageAuthor(thread))"
        :src="getAuthorAvatar(getMessageAuthor(thread))"
        :alt="getAuthorDisplayName(thread)"
        :class="avatarClasses(thread)"
      />
      <div
        v-else
        class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center"
      >
        <span class="text-sm font-medium">{{ getAuthorInitials(thread) }}</span>
      </div>
      <div class="text-xs text-center max-w-20 leading-tight">
        <div>
          {{ getFirstName(getAuthorDisplayName(thread)) }}
        </div>
        <div>
          {{ getLastName(getAuthorDisplayName(thread)) }}
        </div>
      </div>
    </div>

    <div
      :class="[
        'min-w-0 max-w-[85%] sm:max-w-[80%] flex flex-col group/message',
        getMessageDirection(thread.kind) === 'outgoing'
          ? 'items-end'
          : 'items-start',
      ]"
    >
      <!-- Bubble skin -->
      <div
        :class="[
          'w-full rounded-lg p-2 sm:p-3 space-y-2',
          getBubbleClasses(thread),
        ]"
      >
        <!-- Kind badge -->
        <div
          v-if="
            thread.kind !== ThreadKind.ThreadKindTo &&
            thread.kind !== ThreadKind.ThreadKindFrom
          "
          class="flex items-center gap-1 font-medium text-xs mb-1"
          :class="[
            getMessageDirection(thread.kind) === 'outgoing'
              ? 'text-white/90'
              : 'text-foreground/90',
          ]"
        >
          <div
            :class="['w-2 h-2 rounded-full', getKindColor(thread.kind)]"
          ></div>
          <span>{{ getKindLabel(thread.kind) }}</span>
        </div>

        <!-- Edit mode -->
        <div v-if="isEditing" class="text-sm min-w-0 space-y-2">
          <Textarea
            v-model="editableText"
            class="w-full resize-none min-h-[60px] max-h-[160px] bg-background text-foreground"
            :disabled="isSaving"
          />
          <div class="flex justify-end gap-2">
            <Button
              variant="outline"
              size="sm"
              class="bg-background text-foreground hover:bg-muted"
              :disabled="isSaving"
              @click="emit('cancel-edit')"
            >
              Cancel
            </Button>
            <Button
              size="sm"
              class="bg-background text-foreground hover:bg-muted font-medium"
              :disabled="!editableText.trim() || isSaving"
              @click="emit('save-edit')"
            >
              {{ isSaving ? "Saving..." : "Save" }}
            </Button>
          </div>
        </div>

        <!-- VIEW MODE -->
        <div v-else>
          <div v-if="thread.entry" class="text-sm">
            <!-- Email message -->
            <div v-if="emailInfo.isEmail" class="min-w-0 space-y-1.5">
              <div
                class="text-xs rounded-lg p-2.5 mb-2 border flex items-center gap-2.5 min-w-0"
                :class="getHeaderCardClasses(thread)"
              >
                <GmailIcon class="w-4 h-4 shrink-0" />

                <div class="min-w-0 flex-1 space-y-0.5">
                  <div
                    v-if="emailInfo.subject"
                    class="font-medium text-xs flex items-center gap-1 min-w-0"
                    :title="emailInfo.subject"
                  >
                    <span class="opacity-70 font-semibold shrink-0"
                      >Assunto:</span
                    >
                    <span class="truncate min-w-0">{{
                      emailInfo.subject
                    }}</span>
                  </div>
                  <div v-if="emailInfo.from" class="truncate text-[11px]">
                    <span class="font-semibold opacity-70">De:</span>
                    <span class="ml-1">{{ emailInfo.from }}</span>
                  </div>
                  <div v-if="emailInfo.to" class="truncate text-[11px]">
                    <span class="font-semibold opacity-70">Para:</span>
                    <span class="ml-1">{{ emailInfo.to }}</span>
                  </div>
                </div>
              </div>

              <!-- Email body -->
              <div v-if="emailInfo.body" class="leading-relaxed">
                <div
                  v-for="(line, idx) in bodyLines.leadingLines"
                  :key="idx"
                  class="min-h-[1.25rem] whitespace-pre-wrap break-words"
                >
                  {{ line }}
                </div>
                <div class="flex items-baseline justify-between gap-2 min-w-0">
                  <span
                    class="truncate min-w-0 flex-1"
                    :title="bodyLines.lastLine"
                  >
                    {{ bodyLines.lastLine }}
                  </span>
                  <div
                    class="flex items-center gap-1.5 text-[11px] shrink-0 whitespace-nowrap select-none"
                    :class="[
                      getMessageDirection(thread.kind) === 'outgoing'
                        ? 'text-white/70'
                        : 'text-muted-foreground',
                    ]"
                  >
                    <span
                      v-if="
                        thread.entry.updated &&
                        thread.entry.updated !== thread.entry.posted
                      "
                      class="inline-flex items-center gap-1 cursor-help hover:opacity-100"
                      :title="`Edited ${formatFullDateTime(thread.entry.updated)}`"
                    >
                      <Pencil class="w-2.5 h-2.5 inline-block" />
                      <span class="italic">Edited</span>
                    </span>

                    <span
                      class="cursor-help hover:opacity-100"
                      :title="formatFullDateTime(thread.posted)"
                    >
                      {{ formatDate(thread.posted) }}
                    </span>
                  </div>
                </div>
              </div>

              <!-- Fallback if email has no body (only subject balloon) -->
              <div
                v-else
                class="flex items-center justify-end gap-1.5 text-[11px] select-none pt-1"
                :class="[
                  getMessageDirection(thread.kind) === 'outgoing'
                    ? 'text-white/70'
                    : 'text-muted-foreground',
                ]"
              >
                <span
                  v-if="
                    thread.entry.updated &&
                    thread.entry.updated !== thread.entry.posted
                  "
                  class="inline-flex items-center gap-1 cursor-help hover:opacity-100"
                  :title="`Edited ${formatFullDateTime(thread.entry.updated)}`"
                >
                  <Pencil class="w-2.5 h-2.5 inline-block" />
                  <span class="italic">Edited</span>
                </span>

                <span
                  class="cursor-help hover:opacity-100"
                  :title="formatFullDateTime(thread.posted)"
                >
                  {{ formatDate(thread.posted) }}
                </span>
              </div>
            </div>

            <!-- Non-email message (icon removed, date in corner) -->
            <div v-else class="min-w-0">
              <div class="whitespace-pre-wrap break-words leading-relaxed">
                {{ thread.entry.text }}
              </div>

              <!-- Date & Edited status (in bottom-right corner) -->
              <div
                class="flex items-center justify-end gap-1.5 mt-1 select-none text-[11px]"
                :class="[
                  getMessageDirection(thread.kind) === 'outgoing'
                    ? 'text-white/70'
                    : 'text-muted-foreground',
                ]"
              >
                <span
                  v-if="
                    thread.entry.updated &&
                    thread.entry.updated !== thread.entry.posted
                  "
                  class="inline-flex items-center gap-1 cursor-help hover:opacity-100"
                  :title="`Edited ${formatFullDateTime(thread.entry.updated)}`"
                >
                  <Pencil class="w-2.5 h-2.5 inline-block" />
                  <span class="italic">Edited</span>
                </span>

                <span
                  class="cursor-help hover:opacity-100"
                  :title="formatFullDateTime(thread.posted)"
                >
                  {{ formatDate(thread.posted) }}
                </span>
              </div>
            </div>
          </div>

          <!-- Phone call indicator -->
          <div
            v-else-if="thread.kind === ThreadKind.ThreadKindPhoneCall"
            class="text-sm italic flex items-center justify-between gap-2"
          >
            <div class="flex items-center gap-2">
              <span class="text-lg">📞</span>
              <span>Phone call</span>
            </div>
            <span
              class="text-[11px] shrink-0 whitespace-nowrap not-italic select-none cursor-help hover:opacity-100"
              :class="[
                getMessageDirection(thread.kind) === 'outgoing'
                  ? 'text-white/70'
                  : 'text-muted-foreground',
              ]"
              :title="formatFullDateTime(thread.posted)"
            >
              {{ formatDate(thread.posted) }}
            </span>
          </div>

          <!-- Meeting indicator -->
          <div
            v-else-if="thread.meeting"
            class="text-sm italic flex items-center justify-between gap-2"
          >
            <span>📅 Meeting scheduled</span>
            <span
              class="text-[11px] shrink-0 whitespace-nowrap not-italic select-none cursor-help hover:opacity-100"
              :class="[
                getMessageDirection(thread.kind) === 'outgoing'
                  ? 'text-white/70'
                  : 'text-muted-foreground',
              ]"
              :title="formatFullDateTime(thread.posted)"
            >
              {{ formatDate(thread.posted) }}
            </span>
          </div>

          <!-- No content fallback -->
          <div
            v-else
            class="text-sm italic opacity-60 flex items-center justify-between gap-2"
          >
            <span>No message content</span>
            <span
              class="text-[11px] shrink-0 whitespace-nowrap not-italic select-none cursor-help hover:opacity-100"
              :title="formatFullDateTime(thread.posted)"
            >
              {{ formatDate(thread.posted) }}
            </span>
          </div>
        </div>

        <!-- Comments indicator -->
        <div
          v-if="thread.comments.length > 0"
          class="text-xs opacity-75 border-t pt-2"
        >
          💬 {{ thread.comments.length }} comment{{
            thread.comments.length === 1 ? "" : "s"
          }}
        </div>
      </div>

      <!-- Actions -->
      <div class="mt-1 transition-opacity opacity-100">
        <button
          class="p-1 rounded focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black/10 text-muted-foreground hover:opacity-80"
          title="Edit"
          aria-label="Edit message"
          :disabled="isDeleting"
          @click="emit('start-edit', thread)"
        >
          <Pencil :size="16" :stroke-width="2" class="align-middle" />
        </button>
        <button
          class="p-1 rounded focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-destructive/30 text-destructive hover:opacity-90 disabled:opacity-50"
          title="Delete"
          aria-label="Delete message"
          :disabled="isDeleting || isSaving"
          @click="emit('request-delete', thread)"
        >
          <Trash2 :size="16" :stroke-width="2" class="align-middle" />
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { Pencil, Trash2 } from "lucide-vue-next";
import { GmailIcon } from "@/components/icons";
import { ThreadKind, type ThreadWithEntry } from "@/dto/threads";
import type { Company } from "@/dto/companies";
import type { Speaker } from "@/dto/speakers";
import type { Member } from "@/dto/members";
import Image from "../Image.vue";
import Button from "../ui/button/Button.vue";
import Textarea from "../ui/textarea/Textarea.vue";
import {
  parseEmailText,
  splitTextLines,
  formatDate,
  formatFullDateTime,
  getBubbleClasses,
  getHeaderCardClasses,
  getKindLabel,
  getKindColor,
  getMessageDirection,
} from "./utils";

type Author = Member | Speaker | Company;

const props = defineProps<{
  thread: ThreadWithEntry;
  entity: Company | Speaker;
  entityType: "company" | "speaker";
  membersById: Map<string, Member>;
  isEditing: boolean;
  editText: string;
  isSaving: boolean;
  isDeleting: boolean;
}>();

const emit = defineEmits<{
  (event: "update:editText", text: string): void;
  (event: "start-edit", thread: ThreadWithEntry): void;
  (event: "cancel-edit"): void;
  (event: "save-edit"): void;
  (event: "request-delete", thread: ThreadWithEntry): void;
}>();

const editableText = computed({
  get: () => props.editText,
  set: (value: string) => emit("update:editText", value),
});

const emailInfo = computed(() => parseEmailText(props.thread.entry?.text));
const bodyLines = computed(() => splitTextLines(emailInfo.value.body));

const getMessageAuthor = (thread: ThreadWithEntry): Author | null => {
  if (getMessageDirection(thread.kind) === "outgoing") {
    return thread.entry?.member
      ? (props.membersById.get(thread.entry.member) ?? null)
      : null;
  }
  return props.entity;
};

const getAuthorDisplayName = (thread: ThreadWithEntry): string => {
  const email = parseEmailText(thread.entry?.text);
  if (email.isEmail && email.from) {
    const match = email.from.match(/^([^<]+)<[^>]+>/);
    return match ? match[1].trim() : email.from;
  }
  return getMessageAuthor(thread)?.name || "Member";
};

const getAuthorInitials = (thread: ThreadWithEntry): string =>
  getAuthorDisplayName(thread).charAt(0) || "?";

const getAuthorAvatar = (author: Author | null): string | undefined => {
  if (!author) return undefined;
  if ("imgs" in author) return author.imgs?.internal;
  return "img" in author ? author.img : undefined;
};

const avatarClasses = (thread: ThreadWithEntry) => {
  if (
    getMessageDirection(thread.kind) === "outgoing" ||
    props.entityType === "speaker"
  ) {
    return ["w-8 h-8 object-cover", "rounded-full"];
  }
  return [
    "w-8 h-8 bg-white p-1",
    "object-contain",
    "rounded-sm",
    "border border-gray-100",
    "shadow-sm",
    "sm:rounded-none",
    "sm:w-9",
    "sm:h-9",
    "md:w-12",
    "md:h-10",
    "md:rounded-md",
  ];
};

const getFirstName = (name: string): string =>
  name.trim().split(/\s+/)[0] || "Unknown";
const getLastName = (name: string): string => name.trim().split(/\s+/)[1] || "";
</script>
