<template>
  <!-- Channel tabs -->
  <div class="flex flex-col border-b bg-muted/20 flex-shrink-0">
    <div
      class="flex items-center justify-between gap-1.5 px-3 sm:px-4 py-1.5 overflow-x-auto"
    >
      <div class="flex items-center gap-1.5">
        <button
          type="button"
          class="text-xs px-2.5 py-1 rounded-full transition-colors flex items-center gap-1.5 whitespace-nowrap flex-shrink-0 cursor-pointer"
          :class="[
            channel === 'all'
              ? 'bg-primary text-primary-foreground font-medium shadow-xs'
              : 'bg-background hover:bg-muted text-muted-foreground border',
          ]"
          @click="channel = 'all'"
        >
          <span>All</span>
          <span
            class="text-[10px] px-1.5 py-0.2 rounded-full"
            :class="[
              channel === 'all'
                ? 'bg-primary-foreground/20 text-primary-foreground'
                : 'bg-muted text-muted-foreground',
            ]"
          >
            {{ totalCount }}
          </span>
        </button>

        <button
          type="button"
          class="text-xs px-2.5 py-1 rounded-full transition-colors flex items-center gap-1.5 whitespace-nowrap flex-shrink-0 cursor-pointer"
          :class="[
            channel === 'gmail'
              ? 'bg-red-800 text-white font-medium shadow-xs'
              : 'bg-background hover:bg-muted text-muted-foreground border',
          ]"
          @click="channel = 'gmail'"
        >
          <GmailIcon class="w-3.5 h-3.5" />
          <span>Gmail</span>
          <span
            class="text-[10px] px-1.5 py-0.2 rounded-full"
            :class="[
              channel === 'gmail'
                ? 'bg-white/20 text-white'
                : 'bg-muted text-muted-foreground',
            ]"
          >
            {{ gmailCount }}
          </span>
        </button>

        <button
          type="button"
          class="text-xs px-2.5 py-1 rounded-full transition-colors flex items-center gap-1.5 whitespace-nowrap flex-shrink-0 cursor-pointer"
          :class="[
            channel === 'linkedin'
              ? 'bg-blue-800 text-white font-medium shadow-xs'
              : 'bg-background hover:bg-muted text-muted-foreground border',
          ]"
          @click="channel = 'linkedin'"
        >
          <LinkedInIcon class="w-3.5 h-3.5 rounded-[2px]" />
          <span>LinkedIn</span>
          <span
            class="text-[10px] px-1.5 py-0.2 rounded-full"
            :class="[
              channel === 'linkedin'
                ? 'bg-white/20 text-white'
                : 'bg-muted text-muted-foreground',
            ]"
          >
            {{ linkedInCount }}
          </span>
        </button>

        <button
          type="button"
          class="text-xs px-2.5 py-1 rounded-full transition-colors flex items-center gap-1.5 whitespace-nowrap flex-shrink-0 cursor-pointer"
          :class="[
            channel === 'other'
              ? 'bg-zinc-800 text-white font-medium shadow-xs dark:bg-zinc-700'
              : 'bg-background hover:bg-muted text-muted-foreground border',
          ]"
          @click="channel = 'other'"
        >
          <MessageSquare
            class="w-3 h-3"
            :class="channel === 'other' ? 'text-white' : 'text-zinc-500'"
          />
          <span>Outro</span>
          <span
            class="text-[10px] px-1.5 py-0.2 rounded-full"
            :class="[
              channel === 'other'
                ? 'bg-white/20 text-white'
                : 'bg-muted text-muted-foreground',
            ]"
          >
            {{ otherCount }}
          </span>
        </button>
      </div>
    </div>

    <!-- Gmail Sub-threads when in Gmail tab and multiple Gmail threads exist -->
    <div
      v-if="channel === 'gmail' && gmailThreadTabs.length > 1"
      class="flex items-center gap-1.5 px-3 sm:px-4 py-1.5 border-t bg-muted/40 overflow-x-auto"
    >
      <span
        class="text-[11px] font-medium text-muted-foreground mr-1 flex items-center gap-1 flex-shrink-0"
      >
        <Layers class="w-3 h-3" /> Threads:
      </span>
      <button
        v-for="subTab in gmailThreadTabs"
        :key="subTab.id"
        type="button"
        class="text-[11px] px-2 py-0.5 rounded-md transition-colors flex items-center gap-1 whitespace-nowrap flex-shrink-0 cursor-pointer"
        :class="[
          gmailThread === subTab.id
            ? 'bg-red-800 text-white font-medium shadow-xs'
            : 'bg-background/80 hover:bg-muted text-muted-foreground border',
        ]"
        @click="gmailThread = subTab.id"
      >
        <span class="max-w-[140px] sm:max-w-[180px] truncate">{{
          subTab.label
        }}</span>
        <span
          class="text-[9px] px-1 rounded-full"
          :class="[
            gmailThread === subTab.id
              ? 'bg-white/20 text-white'
              : 'bg-muted text-muted-foreground',
          ]"
        >
          {{ subTab.count }}
        </span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { GmailIcon, LinkedInIcon } from "@/components/icons";
import { Layers, MessageSquare } from "lucide-vue-next";
import type { ChannelTab, ThreadGroupInfo } from "./utils";

const channel = defineModel<ChannelTab>("channel", { required: true });
const gmailThread = defineModel<string>("gmailThread", { required: true });

defineProps<{
  totalCount: number;
  gmailCount: number;
  linkedInCount: number;
  otherCount: number;
  gmailThreadTabs: ThreadGroupInfo[];
}>();
</script>
