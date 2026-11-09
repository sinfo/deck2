<template>
  <!-- Message input area -->
  <div v-if="canSendMessages" class="flex-shrink-0 border-t p-3 sm:p-4">
    <!-- Error message -->
    <div
      v-if="errorMessage"
      class="mb-3 p-2 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm"
    >
      <div class="font-medium">Failed to send message</div>
      <div class="text-xs mt-1">
        {{ errorMessage || "Please try again" }}
      </div>
    </div>

    <div class="flex flex-col sm:flex-row gap-2">
      <div class="flex-1 flex flex-col">
        <Textarea
          v-model="newMessage"
          :disabled="disabled"
          :placeholder="
            messageKind === ThreadKind.ThreadKindPhoneCall
              ? 'Registar notas da chamada telefónica...'
              : 'Type your message...'
          "
          class="w-full h-full resize-none border rounded-md p-2 text-sm min-h-[72px] max-h-[120px]"
          @keydown.enter.ctrl="emit('send')"
          @keydown.enter.meta="emit('send')"
          @input="emit('message-input')"
        />
      </div>
      <div class="flex sm:flex-col gap-2">
        <Button
          :disabled="disabled || !newMessage.trim() || isSending"
          size="sm"
          class="px-3 flex-1 sm:flex-none cursor-pointer"
          @click="emit('send')"
        >
          {{ isSending ? "Sending..." : "Send" }}
        </Button>
        <div class="flex gap-1.5 flex-1 sm:flex-none">
          <div
            v-if="messageKind === ThreadKind.ThreadKindPhoneCall"
            class="h-8 text-xs px-2.5 gap-1.5 min-w-[95px] flex-1 sm:flex-none rounded-md border bg-muted/60 dark:bg-muted/40 border-border text-foreground flex items-center select-none"
            title="Chamada Telefónica"
          >
            <Phone class="size-3.5 text-zinc-500 dark:text-zinc-400" />
            <span class="font-medium">Telefone</span>
          </div>

          <!-- Channel Selector (Gmail vs LinkedIn vs Outro) -->
          <Select v-else v-model="messageChannel" :disabled="disabled">
            <SelectTrigger
              size="sm"
              class="h-8 text-xs px-2 gap-1.5 min-w-[95px] flex-1 sm:flex-none"
              title="Plataforma de Comunicação"
            >
              <div class="flex items-center gap-1.5">
                <GmailIcon
                  v-if="messageChannel === ThreadChannel.Gmail"
                  class="size-3.5"
                />
                <LinkedInIcon
                  v-else-if="messageChannel === ThreadChannel.LinkedIn"
                  class="size-3.5 rounded-[2px]"
                />
                <MessageSquare v-else class="size-3.5 opacity-75" />
                <span>{{
                  messageChannel === ThreadChannel.Gmail
                    ? "Gmail"
                    : messageChannel === ThreadChannel.LinkedIn
                      ? "LinkedIn"
                      : "Outro"
                }}</span>
              </div>
            </SelectTrigger>
            <SelectContent>
              <SelectItem :value="ThreadChannel.Gmail" class="text-xs">
                <div class="flex items-center gap-2">
                  <GmailIcon class="size-3.5" />
                  <span>Gmail</span>
                </div>
              </SelectItem>
              <SelectItem :value="ThreadChannel.LinkedIn" class="text-xs">
                <div class="flex items-center gap-2">
                  <LinkedInIcon class="size-3.5 rounded-[2px]" />
                  <span>LinkedIn</span>
                </div>
              </SelectItem>
              <SelectItem :value="ThreadChannel.Other" class="text-xs">
                <div class="flex items-center gap-2">
                  <MessageSquare class="size-3.5 opacity-75" />
                  <span>Outro</span>
                </div>
              </SelectItem>
            </SelectContent>
          </Select>

          <!-- Message Kind/Direction Selector -->
          <Select v-model="messageKind" :disabled="disabled">
            <SelectTrigger
              size="sm"
              class="h-8 text-xs px-2 min-w-[95px] flex-1 sm:flex-none"
              title="Tipo de Mensagem"
            >
              <span>{{
                messageKind === ThreadKind.ThreadKindTo
                  ? "Outgoing"
                  : messageKind === ThreadKind.ThreadKindFrom
                    ? "Incoming"
                    : messageKind === ThreadKind.ThreadKindPhoneCall
                      ? "Phone Call"
                      : "Template"
              }}</span>
            </SelectTrigger>
            <SelectContent>
              <SelectItem :value="ThreadKind.ThreadKindTo" class="text-xs">
                Outgoing
              </SelectItem>
              <SelectItem :value="ThreadKind.ThreadKindFrom" class="text-xs">
                Incoming
              </SelectItem>
              <SelectItem
                :value="ThreadKind.ThreadKindPhoneCall"
                class="text-xs"
              >
                Phone Call
              </SelectItem>
              <SelectItem
                :value="ThreadKind.ThreadKindTemplate"
                class="text-xs"
              >
                Template
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
    </div>
    <div class="text-xs text-muted-foreground mt-2">
      Press Ctrl+Enter to send
    </div>
  </div>
  <div v-else class="flex-shrink-0 border-t p-3 sm:p-4">
    <div class="text-center text-muted-foreground text-sm">
      Communications feature coming soon for {{ entityType }}s
    </div>
  </div>
</template>

<script setup lang="ts">
import { watch } from "vue";
import { ThreadChannel, ThreadKind } from "@/dto/threads";
import { GmailIcon, LinkedInIcon } from "@/components/icons";
import { MessageSquare, Phone } from "lucide-vue-next";
import Button from "../ui/button/Button.vue";
import Textarea from "../ui/textarea/Textarea.vue";
import { Select, SelectContent, SelectItem, SelectTrigger } from "../ui/select";

const newMessage = defineModel<string>("message", { required: true });
const messageChannel = defineModel<ThreadChannel>("channel", {
  required: true,
});
const messageKind = defineModel<ThreadKind>("kind", { required: true });

watch(
  () => messageKind.value,
  (newKind) => {
    if (newKind === ThreadKind.ThreadKindPhoneCall) {
      messageChannel.value = ThreadChannel.Other;
    }
  },
  { immediate: true },
);

const emit = defineEmits<{
  (event: "send"): void;
  (event: "message-input"): void;
}>();

defineProps<{
  entityType: "company" | "speaker";
  canSendMessages: boolean;
  disabled: boolean;
  isSending: boolean;
  errorMessage?: string;
}>();
</script>
