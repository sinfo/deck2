<script setup lang="ts">
import { computed } from "vue";
import { ThreadChannel } from "@/dto/threads";
import { GmailIcon, LinkedInIcon } from "@/components/icons";
import { MessageSquare } from "lucide-vue-next";

const props = withDefaults(
  defineProps<{
    channel: ThreadChannel;
    isOutgoing?: boolean;
    bare?: boolean;
  }>(),
  {
    isOutgoing: false,
    bare: false,
  },
);

const tileClasses = computed(() => {
  if (props.isOutgoing) {
    return "bg-white/10 border-white/20 text-white";
  }

  if (props.channel === ThreadChannel.LinkedIn) {
    return "bg-white/90 dark:bg-black/40 border-blue-200/80 dark:border-blue-900/60 text-blue-950 dark:text-blue-200";
  }
  if (props.channel === ThreadChannel.Other) {
    return "bg-white/90 dark:bg-black/40 border-zinc-200/80 dark:border-zinc-800 text-zinc-950 dark:text-zinc-200";
  }
  // Gmail (default)
  return "bg-white/90 dark:bg-black/40 border-red-200/80 dark:border-red-900/60 text-red-950 dark:text-red-200";
});
</script>

<template>
  <div
    v-if="!bare"
    class="grid place-items-center w-9 h-9 rounded-lg shrink-0 select-none border"
    :class="tileClasses"
  >
    <LinkedInIcon
      v-if="channel === ThreadChannel.LinkedIn"
      class="w-6 h-6 block"
      title="LinkedIn"
    />
    <GmailIcon
      v-else-if="channel === ThreadChannel.Gmail"
      class="w-6 h-6 block"
      title="Gmail"
    />
    <MessageSquare v-else class="w-5 h-5 block opacity-80" title="Outro" />
  </div>
  <template v-else>
    <LinkedInIcon
      v-if="channel === ThreadChannel.LinkedIn"
      class="w-6 h-6 shrink-0 block rounded-[2px]"
      title="LinkedIn"
    />
    <GmailIcon
      v-else-if="channel === ThreadChannel.Gmail"
      class="w-6 h-6 shrink-0 block"
      title="Gmail"
    />
    <MessageSquare
      v-else
      class="w-5 h-5 shrink-0 block opacity-80"
      title="Outro"
    />
  </template>
</template>
