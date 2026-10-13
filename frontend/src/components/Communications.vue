<template>
  <Card class="w-full h-auto lg:h-[650px] 2xl:h-[800px] flex flex-col">
    <CardHeader class="flex-shrink-0">
      <div
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-2"
      >
        <div class="flex-1">
          <CardTitle class="text-base sm:text-lg"> Communications</CardTitle>
          <CardDescription class="text-sm">
            {{ description }}
          </CardDescription>
        </div>
        <div v-if="templates?.length" class="flex-shrink-0">
          <Select
            v-model="selectedTemplate"
            :disabled="selectedEventId !== latestEvent?.id"
          >
            <SelectTrigger>
              <SelectValue placeholder="Templates" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem
                v-for="template in templates"
                :key="template.template"
                :value="template"
              >
                {{ templateHumanReadableNames[template.template] }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div class="flex-shrink-0 flex gap-1">
          <TooltipProvider>
            <Tooltip>
              <TooltipTrigger as-child>
                <Button
                  variant="outline"
                  size="sm"
                  :class="[
                    currentParticipationGmailThreadIds.length > 0
                      ? 'text-blue-500 border-blue-500'
                      : '',
                  ]"
                  :disabled="!selectedEventId"
                  @click="openGmailPicker"
                >
                  <GmailIcon class="w-4 h-4 mr-1.5" />
                  <span v-if="currentParticipationGmailThreadIds.length > 0">
                    {{ currentParticipationGmailThreadIds.length }} Gmail
                  </span>
                  <span v-else>Link Gmail</span>
                </Button>
              </TooltipTrigger>
              <TooltipContent>
                <p>
                  {{
                    currentParticipationGmailThreadIds.length > 0
                      ? `${currentParticipationGmailThreadIds.length} Gmail thread(s) linked`
                      : "Link Gmail threads to this participation"
                  }}
                </p>
              </TooltipContent>
            </Tooltip>
          </TooltipProvider>
          <TooltipProvider>
            <Tooltip>
              <TooltipTrigger as-child>
                <Button
                  variant="outline"
                  size="sm"
                  :disabled="
                    !selectedEventId ||
                    currentParticipationGmailThreadIds.length === 0 ||
                    isSyncing
                  "
                  @click="syncGmailMessages"
                >
                  <RefreshCw
                    :size="16"
                    :stroke-width="2"
                    :class="[isSyncing ? 'animate-spin' : '']"
                  />
                </Button>
              </TooltipTrigger>
              <TooltipContent>
                <p>Sync Gmail messages to communications</p>
              </TooltipContent>
            </Tooltip>
          </TooltipProvider>
        </div>
        <div class="flex-shrink-0">
          <Select v-model="selectedEventId">
            <SelectTrigger>
              <SelectValue placeholder="Edition" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem
                v-for="event in availableEvents"
                :key="event.id"
                :value="event.id"
              >
                {{ event.name }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
    </CardHeader>

    <CardContent class="flex-1 flex flex-col overflow-hidden p-0">
      <div v-if="isLoading" class="flex-1 flex items-center justify-center">
        <div class="text-muted-foreground">Loading communications...</div>
      </div>

      <div v-else-if="error" class="flex-1 flex items-center justify-center">
        <div class="text-center text-red-500">
          <div class="text-lg mb-2">⚠️</div>
          <div>Failed to load communications</div>
          <div class="text-xs">{{ error?.message }}</div>
        </div>
      </div>

      <div
        v-else-if="!sortedCommunications?.length"
        class="flex-1 flex items-center justify-center p-6"
      >
        <!-- Notice when entity is contacted but no Gmail thread could be linked -->
        <div
          v-if="isContactedWithoutThread"
          class="text-center max-w-sm mx-auto space-y-3"
        >
          <div
            class="w-12 h-12 rounded-full bg-amber-500/10 text-amber-600 dark:text-amber-400 flex items-center justify-center mx-auto"
          >
            <MailWarning class="w-6 h-6" />
          </div>
          <div class="space-y-1">
            <h3 class="font-semibold text-sm">No Gmail thread found</h3>
            <p class="text-xs text-muted-foreground leading-relaxed">
              This {{ entityType }} is marked as
              <strong class="text-foreground font-semibold">{{
                currentStatusLabel
              }}</strong
              >, but no matching email thread was found automatically in Gmail.
            </p>
          </div>
          <div class="pt-1">
            <Button
              variant="outline"
              size="sm"
              class="gap-1.5 text-xs"
              @click="openGmailPicker"
            >
              <Link2 class="w-3.5 h-3.5" />
              Link Gmail thread manually
            </Button>
          </div>
          <div v-if="selectedEventId" class="text-[11px] opacity-60">
            For event: {{ getEventName(selectedEventId) }}
          </div>
        </div>

        <div v-else class="text-center text-muted-foreground">
          <div class="text-lg mb-2">💬</div>
          <div>No communications yet</div>
          <div class="text-xs">
            Start a conversation with this {{ entityType }}
          </div>
          <div v-if="selectedEventId" class="text-xs mt-2 opacity-60">
            For event: {{ getEventName(selectedEventId) }}
          </div>
          <div v-else class="text-xs mt-2 opacity-60 text-red-500">
            No event selected
          </div>
        </div>
      </div>

      <div v-else class="flex-1 flex flex-col overflow-hidden">
        <!-- Warning banner when communications exist but Gmail thread is not linked -->
        <div
          v-if="
            isContactedWithoutThread &&
            selectedChannelTab !== 'linkedin' &&
            selectedChannelTab !== 'other'
          "
          class="mx-3 mt-2 mb-1 p-2.5 rounded-md border border-amber-500/30 bg-amber-500/10 text-amber-800 dark:text-amber-300 text-xs flex items-center justify-between gap-2 flex-shrink-0"
        >
          <div class="flex items-center gap-2 min-w-0">
            <AlertTriangle
              class="w-4 h-4 text-amber-600 dark:text-amber-400 flex-shrink-0"
            />
            <span class="truncate">
              Marked as <strong>{{ currentStatusLabel }}</strong
              >, but no Gmail thread is linked.
            </span>
          </div>
          <Button
            variant="outline"
            size="sm"
            class="h-7 text-xs px-2.5 border-amber-500/30 hover:bg-amber-500/20 flex-shrink-0 gap-1"
            @click="openGmailPicker"
          >
            <Link2 class="w-3 h-3" />
            Link thread
          </Button>
        </div>

        <!-- Channel tabs selector: All | Gmail | LinkedIn -->
        <div class="flex flex-col border-b bg-muted/20 flex-shrink-0">
          <div
            class="flex items-center justify-between gap-1.5 px-3 sm:px-4 py-2 overflow-x-auto"
          >
            <div class="flex items-center gap-1.5">
              <!-- All tab -->
              <button
                type="button"
                class="text-xs px-2.5 py-1 rounded-full transition-colors flex items-center gap-1.5 whitespace-nowrap flex-shrink-0 cursor-pointer"
                :class="[
                  selectedChannelTab === 'all'
                    ? 'bg-primary text-primary-foreground font-medium shadow-xs'
                    : 'bg-background hover:bg-muted text-muted-foreground border',
                ]"
                @click="selectedChannelTab = 'all'"
              >
                <span>All</span>
                <span
                  class="text-[10px] px-1.5 py-0.2 rounded-full"
                  :class="[
                    selectedChannelTab === 'all'
                      ? 'bg-primary-foreground/20 text-primary-foreground'
                      : 'bg-muted text-muted-foreground',
                  ]"
                >
                  {{ sortedCommunications.length }}
                </span>
              </button>

              <!-- Gmail tab -->
              <button
                type="button"
                class="text-xs px-2.5 py-1 rounded-full transition-colors flex items-center gap-1.5 whitespace-nowrap flex-shrink-0 cursor-pointer"
                :class="[
                  selectedChannelTab === 'gmail'
                    ? 'bg-red-800 text-white font-medium shadow-xs'
                    : 'bg-background hover:bg-muted text-muted-foreground border',
                ]"
                @click="selectedChannelTab = 'gmail'"
              >
                <GmailIcon class="w-3.5 h-3.5" />
                <span>Gmail</span>
                <span
                  class="text-[10px] px-1.5 py-0.2 rounded-full"
                  :class="[
                    selectedChannelTab === 'gmail'
                      ? 'bg-white/20 text-white'
                      : 'bg-muted text-muted-foreground',
                  ]"
                >
                  {{ gmailCommunicationsCount }}
                </span>
              </button>

              <!-- LinkedIn tab -->
              <button
                type="button"
                class="text-xs px-2.5 py-1 rounded-full transition-colors flex items-center gap-1.5 whitespace-nowrap flex-shrink-0 cursor-pointer"
                :class="[
                  selectedChannelTab === 'linkedin'
                    ? 'bg-blue-800 text-white font-medium shadow-xs'
                    : 'bg-background hover:bg-muted text-muted-foreground border',
                ]"
                @click="selectedChannelTab = 'linkedin'"
              >
                <LinkedInIcon class="w-3.5 h-3.5 rounded-[2px]" />
                <span>LinkedIn</span>
                <span
                  class="text-[10px] px-1.5 py-0.2 rounded-full"
                  :class="[
                    selectedChannelTab === 'linkedin'
                      ? 'bg-white/20 text-white'
                      : 'bg-muted text-muted-foreground',
                  ]"
                >
                  {{ linkedInCommunicationsCount }}
                </span>
              </button>

              <!-- Outro tab -->
              <button
                type="button"
                class="text-xs px-2.5 py-1 rounded-full transition-colors flex items-center gap-1.5 whitespace-nowrap flex-shrink-0 cursor-pointer"
                :class="[
                  selectedChannelTab === 'other'
                    ? 'bg-zinc-800 text-white font-medium shadow-xs dark:bg-zinc-700'
                    : 'bg-background hover:bg-muted text-muted-foreground border',
                ]"
                @click="selectedChannelTab = 'other'"
              >
                <MessageSquare
                  class="w-3 h-3"
                  :class="
                    selectedChannelTab === 'other'
                      ? 'text-white'
                      : 'text-zinc-500'
                  "
                />
                <span>Outro</span>
                <span
                  class="text-[10px] px-1.5 py-0.2 rounded-full"
                  :class="[
                    selectedChannelTab === 'other'
                      ? 'bg-white/20 text-white'
                      : 'bg-muted text-muted-foreground',
                  ]"
                >
                  {{ otherCommunicationsCount }}
                </span>
              </button>
            </div>
          </div>

          <!-- Gmail Sub-threads when in Gmail tab and multiple Gmail threads exist -->
          <div
            v-if="
              selectedChannelTab === 'gmail' &&
              availableGmailThreadTabs.length > 1
            "
            class="flex items-center gap-1.5 px-3 sm:px-4 py-1.5 border-t bg-muted/40 overflow-x-auto"
          >
            <span
              class="text-[11px] font-medium text-muted-foreground mr-1 flex items-center gap-1 flex-shrink-0"
            >
              <Layers class="w-3 h-3" /> Threads:
            </span>
            <button
              v-for="subTab in availableGmailThreadTabs"
              :key="subTab.id"
              type="button"
              class="text-[11px] px-2 py-0.5 rounded-md transition-colors flex items-center gap-1 whitespace-nowrap flex-shrink-0 cursor-pointer"
              :class="[
                selectedGmailThreadTab === subTab.id
                  ? 'bg-red-800 text-white font-medium shadow-xs'
                  : 'bg-background/80 hover:bg-muted text-muted-foreground border',
              ]"
              @click="selectedGmailThreadTab = subTab.id"
            >
              <span class="max-w-[140px] sm:max-w-[180px] truncate">{{
                subTab.label
              }}</span>
              <span
                class="text-[9px] px-1 rounded-full"
                :class="[
                  selectedGmailThreadTab === subTab.id
                    ? 'bg-white/20 text-white'
                    : 'bg-muted text-muted-foreground',
                ]"
              >
                {{ subTab.count }}
              </span>
            </button>
          </div>
        </div>

        <div
          ref="messagesContainer"
          class="flex-1 overflow-y-auto p-2 sm:p-4 space-y-3 sm:space-y-4 scroll-smooth"
        >
          <!-- Filtered empty state -->
          <div
            v-if="filteredCommunications.length === 0"
            class="h-full flex items-center justify-center p-8 text-center text-muted-foreground"
          >
            <div class="flex flex-col items-center">
              <div class="mb-3 flex justify-center">
                <LinkedInIcon
                  v-if="selectedChannelTab === 'linkedin'"
                  class="w-10 h-10 rounded-sm"
                />
                <GmailIcon
                  v-else-if="selectedChannelTab === 'gmail'"
                  class="w-10 h-10"
                />
                <MessageSquare
                  v-else
                  class="w-10 h-10 text-muted-foreground/60"
                />
              </div>
              <div class="text-sm font-medium">
                {{
                  selectedChannelTab === "linkedin"
                    ? "Sem comunicações do LinkedIn"
                    : selectedChannelTab === "gmail"
                      ? "Sem comunicações do Gmail"
                      : "Sem comunicações de Outro"
                }}
              </div>
              <div class="text-xs opacity-70 mt-1">
                Alterne para a aba "All" ou envie uma mensagem neste canal.
              </div>
            </div>
          </div>

          <template
            v-for="(thread, index) in filteredCommunications"
            :key="thread.id"
          >
            <!-- Thread visual divider when viewing all and thread changes -->
            <div
              v-if="showThreadDivider(index)"
              class="flex items-center gap-2 my-3 text-xs text-muted-foreground"
            >
              <div class="h-px bg-border flex-1"></div>
              <Badge
                variant="outline"
                class="font-normal text-[11px] gap-1 py-0.5"
              >
                <LinkedInIcon
                  v-if="getThreadChannel(thread) === ThreadChannel.LinkedIn"
                  class="w-3 h-3 rounded-[2px]"
                />
                <MessageSquare
                  v-else-if="getThreadChannel(thread) === ThreadChannel.Other"
                  class="w-3 h-3 text-zinc-500"
                />
                <GmailIcon v-else class="w-3 h-3" />
                <span class="max-w-[220px] sm:max-w-[320px] truncate">
                  {{ getDividerLabel(thread) }}
                </span>
              </Badge>
              <div class="h-px bg-border flex-1"></div>
            </div>

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
                  <span class="text-sm font-medium">{{
                    getAuthorInitials(thread)
                  }}</span>
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
                  'max-w-[85%] sm:max-w-[80%] flex flex-col group/message',
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
                  <!-- Message header -->
                  <div class="flex items-center justify-between gap-3 text-xs">
                    <div class="flex items-center gap-2">
                      <!-- Channel Logo in elevated micro-tile with same background as subject card -->
                      <div
                        class="grid place-items-center w-9 h-9 rounded-lg shrink-0 select-none border"
                        :class="getChannelTileClasses(thread)"
                      >
                        <LinkedInIcon
                          v-if="
                            getThreadChannel(thread) === ThreadChannel.LinkedIn
                          "
                          class="w-6 h-6 block"
                          title="LinkedIn"
                        />
                        <GmailIcon
                          v-else-if="
                            getThreadChannel(thread) === ThreadChannel.Gmail
                          "
                          class="w-6 h-6 block"
                          title="Gmail"
                        />
                        <MessageSquare
                          v-else
                          class="w-5 h-5 block opacity-80"
                          title="Outro"
                        />
                      </div>

                      <!-- Special kind badge if not standard Sent/Received (e.g. Phone Call, Meeting, Template) -->
                      <div
                        v-if="
                          thread.kind !== ThreadKind.ThreadKindTo &&
                          thread.kind !== ThreadKind.ThreadKindFrom
                        "
                        class="flex items-center gap-1 font-medium"
                        :class="[
                          getMessageDirection(thread.kind) === 'outgoing'
                            ? 'text-white/90'
                            : 'text-foreground/90',
                        ]"
                      >
                        <div
                          :class="[
                            'w-2 h-2 rounded-full',
                            getKindColor(thread.kind),
                          ]"
                        ></div>
                        <span>{{ getKindLabel(thread.kind) }}</span>
                      </div>
                    </div>

                    <span
                      :class="[
                        getMessageDirection(thread.kind) === 'outgoing'
                          ? 'text-white/70'
                          : 'text-muted-foreground',
                      ]"
                      class="shrink-0"
                    >
                      {{ formatDate(thread.posted) }}
                    </span>
                  </div>

                  <!-- Edit mode -->
                  <div
                    v-if="editingThreadId === thread.id"
                    class="text-sm space-y-2"
                  >
                    <Textarea
                      v-model="editText"
                      class="w-full resize-none min-h-[60px] max-h-[160px] bg-background text-foreground"
                      :disabled="updatePostMutation?.isLoading?.value"
                    />
                    <div class="flex justify-end gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        class="bg-background text-foreground hover:bg-muted"
                        :disabled="updatePostMutation?.isLoading?.value"
                        @click="cancelEdit"
                      >
                        Cancel
                      </Button>
                      <Button
                        size="sm"
                        class="bg-background text-foreground hover:bg-muted font-medium"
                        :disabled="
                          !editText.trim() ||
                          updatePostMutation?.isLoading?.value
                        "
                        @click="saveEdit"
                      >
                        {{
                          updatePostMutation?.isLoading?.value
                            ? "Saving..."
                            : "Save"
                        }}
                      </Button>
                    </div>
                  </div>

                  <!-- VIEW MODE -->
                  <div v-else>
                    <!-- Message content -->
                    <div v-if="thread.entry" class="text-sm">
                      <!-- Synced Email Header Card -->
                      <div
                        v-if="parseEmailText(thread.entry.text).isEmail"
                        class="space-y-1.5"
                      >
                        <div
                          class="text-xs rounded p-2 mb-2 space-y-0.5 border"
                          :class="[
                            getMessageDirection(thread.kind) === 'outgoing'
                              ? 'bg-white/10 border-white/20 text-white'
                              : 'bg-white/80 dark:bg-black/30 border-red-200/60 dark:border-red-900/40 text-red-950 dark:text-red-200',
                          ]"
                        >
                          <div
                            v-if="parseEmailText(thread.entry.text).subject"
                            class="font-medium text-xs truncate flex items-center gap-1"
                            :class="[
                              getMessageDirection(thread.kind) === 'outgoing'
                                ? 'text-white'
                                : 'text-red-950 dark:text-red-100',
                            ]"
                          >
                            <span class="opacity-70 font-semibold"
                              >Assunto:</span
                            >
                            <span>{{
                              parseEmailText(thread.entry.text).subject
                            }}</span>
                          </div>
                          <div
                            v-if="parseEmailText(thread.entry.text).from"
                            class="truncate text-[11px]"
                          >
                            <span class="font-semibold opacity-70">De:</span>
                            <span class="ml-1">{{
                              parseEmailText(thread.entry.text).from
                            }}</span>
                          </div>
                          <div
                            v-if="parseEmailText(thread.entry.text).to"
                            class="truncate text-[11px]"
                          >
                            <span class="font-semibold opacity-70">Para:</span>
                            <span class="ml-1">{{
                              parseEmailText(thread.entry.text).to
                            }}</span>
                          </div>
                        </div>
                        <!-- Email body -->
                        <div class="whitespace-pre-wrap leading-relaxed">
                          {{ parseEmailText(thread.entry.text).body }}
                        </div>
                      </div>
                      <div v-else class="whitespace-pre-wrap">
                        {{ thread.entry.text }}
                      </div>
                      <div
                        v-if="
                          thread.entry.updated &&
                          thread.entry.updated !== thread.entry.posted
                        "
                        class="text-xs opacity-60 mt-1"
                      >
                        Edited {{ formatDate(thread.entry.updated) }}
                      </div>
                    </div>

                    <!-- Phone call indicator -->
                    <div
                      v-else-if="thread.kind === ThreadKind.ThreadKindPhoneCall"
                      class="text-sm italic flex items-center justify-center gap-2"
                    >
                      <span class="text-lg">📞</span>
                      <span>Phone call</span>
                    </div>

                    <!-- Meeting indicator -->
                    <div v-else-if="thread.meeting" class="text-sm italic">
                      📅 Meeting scheduled
                    </div>

                    <!-- No content fallback -->
                    <div v-else class="text-sm italic opacity-60">
                      No message content
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
                <div :class="['mt-1 transition-opacity opacity-100']">
                  <button
                    class="p-1 rounded focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black/10 text-muted-foreground hover:opacity-80"
                    title="Edit"
                    aria-label="Edit message"
                    :disabled="deleteThreadMutation?.isLoading?.value"
                    @click="startEdit(thread)"
                  >
                    <Pencil :size="16" :stroke-width="2" class="align-middle" />
                  </button>
                  <button
                    class="p-1 rounded focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-destructive/30 text-destructive hover:opacity-90 disabled:opacity-50"
                    title="Delete"
                    aria-label="Delete message"
                    :disabled="
                      deleteThreadMutation?.isLoading?.value ||
                      updatePostMutation?.isLoading?.value
                    "
                    @click="requestDelete(thread)"
                  >
                    <Trash2 :size="16" :stroke-width="2" class="align-middle" />
                  </button>
                </div>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Message input area -->
      <div v-if="canSendMessages" class="flex-shrink-0 border-t p-3 sm:p-4">
        <!-- Error message -->
        <div
          v-if="postThreadMutation?.error.value"
          class="mb-3 p-2 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm"
        >
          <div class="font-medium">Failed to send message</div>
          <div class="text-xs mt-1">
            {{ postThreadMutation.error.value.message || "Please try again" }}
          </div>
        </div>

        <div class="flex flex-col sm:flex-row gap-2">
          <div class="flex-1">
            <Textarea
              v-model="newMessage"
              :disabled="selectedEventId !== latestEvent?.id"
              placeholder="Type your message..."
              class="w-full resize-none border rounded-md p-2 text-sm min-h-[50px] sm:min-h-[60px] max-h-[100px] sm:max-h-[120px]"
              @keydown.enter.ctrl="sendMessage"
              @keydown.enter.meta="sendMessage"
              @input="onMessageInput"
            />
          </div>
          <div class="flex sm:flex-col gap-2">
            <Button
              :disabled="
                selectedEventId !== latestEvent?.id ||
                !newMessage.trim() ||
                postThreadMutation?.isLoading.value
              "
              size="sm"
              class="px-3 flex-1 sm:flex-none cursor-pointer"
              @click="sendMessage"
            >
              {{ postThreadMutation?.isLoading.value ? "Sending..." : "Send" }}
            </Button>
            <div class="flex gap-1.5 flex-1 sm:flex-none">
              <!-- Channel Selector (Gmail vs LinkedIn vs Outro) -->
              <Select
                v-model="messageChannel"
                :disabled="selectedEventId !== latestEvent?.id"
              >
                <SelectTrigger
                  size="sm"
                  class="h-7 text-xs px-2 gap-1.5 min-w-[95px] flex-1 sm:flex-none"
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
              <Select
                v-model="messageKind"
                :disabled="selectedEventId !== latestEvent?.id"
              >
                <SelectTrigger
                  size="sm"
                  class="h-7 text-xs px-2 min-w-[95px] flex-1 sm:flex-none"
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
                  <SelectItem
                    :value="ThreadKind.ThreadKindFrom"
                    class="text-xs"
                  >
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
    </CardContent>
  </Card>

  <!-- Gmail Thread Picker Modal -->
  <GmailThreadPicker
    v-model:open="isGmailPickerOpen"
    :initial-thread-ids="gmailPickerThreadIds"
    :default-search-query="gmailPickerDefaultQuery"
    @save="handleGmailThreadsSave"
  />
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from "vue";
import { useQuery, useQueryCache } from "@pinia/colada";
import { getAllEvents } from "@/api/events";
import { getAllMembers } from "@/api/members";
import {
  updateCompanyGmailThreadIds,
  syncCompanyGmailMessages,
} from "@/api/companies";
import {
  updateSpeakerGmailThreadIds,
  syncSpeakerGmailMessages,
} from "@/api/speakers";
import { ThreadChannel, ThreadKind } from "@/dto/threads";
import type {
  ParticipationCommunications,
  ThreadWithEntry,
} from "@/dto/threads";
import type { Speaker } from "@/dto/speakers";
import type { Company } from "@/dto/companies";
import type { Member } from "@/dto/members";
import { useEventStore } from "@/stores/event";
import { useAuthStore } from "@/stores/auth";
import { useGmailMessages } from "@/composables/useGmailMessages";
import { useAutoLinkGmail } from "@/composables/useAutoLinkGmail";
import Card from "./ui/card/Card.vue";
import CardContent from "./ui/card/CardContent.vue";
import CardDescription from "./ui/card/CardDescription.vue";
import CardHeader from "./ui/card/CardHeader.vue";
import CardTitle from "./ui/card/CardTitle.vue";
import Button from "./ui/button/Button.vue";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "./ui/select";
import Image from "./Image.vue";
import {
  EmailTemplate,
  openTemplateInNewTab,
  templateHumanReadableNames,
  type AnyEmailVariableInput,
} from "@/lib/templates";
import type { Event } from "@/dto/events";
import type { ParticipationStatus } from "@/dto";
import { humanReadableParticipationStatus } from "@/dto";
import Textarea from "./ui/textarea/Textarea.vue";
import { useUpdatePostMutation } from "@/mutations/posts.ts";
import { GmailIcon, LinkedInIcon } from "@/components/icons";
import {
  Pencil,
  Trash2,
  RefreshCw,
  Layers,
  AlertTriangle,
  MailWarning,
  Link2,
  MessageSquare,
} from "lucide-vue-next";
import { Badge } from "@/components/ui/badge";
import { useDeleteThreadMutation } from "@/mutations/threads.ts";
import GmailThreadPicker from "./GmailThreadPicker.vue";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "./ui/tooltip";

interface TemplateWithVariables {
  template: EmailTemplate;
  variables: AnyEmailVariableInput[];
}

interface CommunicationsProps {
  entity: Company | Speaker;
  entityType: "company" | "speaker";
  description: string;
  participations?: Array<{
    event: number;
    status?: ParticipationStatus;
    gmailThreadIds?: string[];
  }>;
  canSendMessages?: boolean;
  templates?: TemplateWithVariables[];
  fetchCommunications: (
    id: string,
  ) => Promise<{ data: ParticipationCommunications[] }>;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  postThreadMutation?: any;
}

type Author = Member | Speaker | Company;

const props = withDefaults(defineProps<CommunicationsProps>(), {
  canSendMessages: false,
  templates: () => [],
  participations: () => [],
  postThreadMutation: undefined,
});

const newMessage = ref("");
const messageKind = ref<ThreadKind>(ThreadKind.ThreadKindTo);
const messageChannel = ref<ThreadChannel>(ThreadChannel.Gmail);
const messagesContainer = ref<HTMLElement>();
const eventStore = useEventStore();
const selectedEventId = ref<number | null>(
  eventStore.selectedEvent?.id ?? null,
);
const selectedTemplate = ref<TemplateWithVariables>();

const editingThreadId = ref<string | null>(null);
const editingPostId = ref<string | null>(null);
const editText = ref("");

// Gmail thread picker state
const isGmailPickerOpen = ref(false);
const gmailPickerThreadIds = ref<string[]>([]);
const gmailPickerDefaultQuery = ref("");
const queryCache = useQueryCache();

const updatePostMutation = useUpdatePostMutation();
const deleteThreadMutation = useDeleteThreadMutation();

updatePostMutation.entityType.value = props.entityType;
updatePostMutation.entityId.value = props.entity.id;
deleteThreadMutation.entityType.value = props.entityType;
deleteThreadMutation.entityId.value = props.entity.id;

const scrollToBottom = () => {
  nextTick(() => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTo({
        top: messagesContainer.value.scrollHeight,
        behavior: "smooth",
      });
    }
  });
};

// Fetch all events to get proper names
const { data: eventsData } = useQuery({
  key: () => ["events"],
  query: () => getAllEvents(),
});

// Fetch all members to get names and avatars
const { data: membersData } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers(),
});

// Computed property to get events with participations
const availableEvents = computed(() => {
  if (!props.participations || !eventsData.value?.data) return [];

  const events = eventsData.value.data;
  const participationEventIds = new Set(
    props.participations.map((p) => p.event),
  );

  return events
    .filter((event) => participationEventIds.has(event.id))
    .map((event) => ({
      id: event.id,
      name: event.name,
    }));
});

const membersById = computed(() => {
  if (!membersData.value?.data) return new Map();

  const map = new Map();
  membersData.value.data.forEach((member) => {
    map.set(member.id, member);
  });
  return map;
});

const {
  data: communicationsData,
  isLoading,
  error,
} = useQuery({
  key: () => [`${props.entityType}-communications`, props.entity.id],
  query: () => props.fetchCommunications(props.entity.id).then((it) => it.data),
});

const sortedCommunications = computed<ThreadWithEntry[]>(() => {
  if (!communicationsData.value) return [];
  return [...communicationsData.value]
    .filter((it) => it.event === selectedEventId.value)
    .flatMap((it) => it.communications)
    .sort(
      (a, b) => new Date(a.posted).getTime() - new Date(b.posted).getTime(),
    ) as ThreadWithEntry[];
});

interface ParsedEmailContent {
  isEmail: boolean;
  subject?: string;
  from?: string;
  to?: string;
  body: string;
}

// Cache parsed email headers and bodies across template render cycles to avoid repetitive regex/string work.
const emailParseCache = new Map<string, ParsedEmailContent>();

const parseEmailText = (text?: string): ParsedEmailContent => {
  if (!text) return { isEmail: false, body: "" };
  const cached = emailParseCache.get(text);
  if (cached) return cached;

  const lines = text.split("\n");
  let subject: string | undefined;
  let from: string | undefined;
  let to: string | undefined;
  let headerEndIndex = -1;

  for (let i = 0; i < Math.min(lines.length, 6); i++) {
    const line = lines[i].trim();
    if (line.startsWith("📧")) {
      subject = line.replace(/^📧\s*/, "").trim();
      headerEndIndex = i;
    } else if (line.startsWith("De:") || line.startsWith("From:")) {
      from = line.replace(/^(De|From):\s*/, "").trim();
      headerEndIndex = i;
    } else if (line.startsWith("Para:") || line.startsWith("To:")) {
      to = line.replace(/^(Para|To):\s*/, "").trim();
      headerEndIndex = i;
    } else if (line === "" && (subject || from || to)) {
      headerEndIndex = i;
      break;
    }
  }

  const isEmail = Boolean(subject || from || to);
  let result: ParsedEmailContent;
  if (!isEmail) {
    result = { isEmail: false, body: text };
  } else {
    const body = lines
      .slice(headerEndIndex + 1)
      .join("\n")
      .trim();
    result = {
      isEmail: true,
      subject,
      from,
      to,
      body: body || text,
    };
  }

  if (emailParseCache.size > 200) {
    emailParseCache.clear();
  }
  emailParseCache.set(text, result);
  return result;
};

// Returns conversation group key (gmailThreadId or parsed email subject) to separate distinct threads.
const getThreadKey = (thread: ThreadWithEntry): string | null => {
  if (thread.gmailThreadId) return thread.gmailThreadId;
  const emailInfo = parseEmailText(thread.entry?.text);
  if (emailInfo.isEmail && emailInfo.subject) {
    return `subject:${emailInfo.subject}`;
  }
  return null;
};

const getAuthorDisplayName = (thread: ThreadWithEntry): string => {
  const emailInfo = parseEmailText(thread.entry?.text);
  if (emailInfo.isEmail && emailInfo.from) {
    const match = emailInfo.from.match(/^([^<]+)<[^>]+>/);
    return match ? match[1].trim() : emailInfo.from;
  }
  return getMessageAuthor(thread)?.name || "Member";
};

const getAuthorInitials = (thread: ThreadWithEntry): string => {
  const name = getAuthorDisplayName(thread);
  return name.charAt(0) || "?";
};

const selectedChannelTab = ref<"all" | "gmail" | "linkedin" | "other">("all");
const selectedGmailThreadTab = ref<string>("all");

interface ThreadGroupInfo {
  id: string;
  label: string;
  sender?: string;
  count: number;
}

const getThreadChannel = (thread: ThreadWithEntry): ThreadChannel => {
  if (thread.channel === ThreadChannel.LinkedIn) {
    return ThreadChannel.LinkedIn;
  }
  if (thread.channel === ThreadChannel.Other) {
    return ThreadChannel.Other;
  }
  if (thread.channel === ThreadChannel.Gmail) {
    return ThreadChannel.Gmail;
  }
  if (
    thread.gmailMessageId ||
    thread.gmailThreadId ||
    thread.kind === ThreadKind.ThreadKindTemplate
  ) {
    return ThreadChannel.Gmail;
  }
  return ThreadChannel.Gmail;
};

const getBubbleClasses = (thread: ThreadWithEntry): string => {
  if (thread.kind === ThreadKind.ThreadKindPhoneCall) {
    return "bg-purple-100 text-purple-900 border border-purple-200 dark:bg-purple-950/60 dark:text-purple-200 dark:border-purple-900";
  }

  const isOutgoing = getMessageDirection(thread.kind) === "outgoing";
  const channel = getThreadChannel(thread);

  if (channel === ThreadChannel.LinkedIn) {
    return isOutgoing
      ? "bg-blue-800 text-white border border-blue-900 shadow-xs dark:bg-blue-900 dark:text-blue-50"
      : "bg-blue-100 text-blue-950 border border-blue-200 dark:bg-blue-950/50 dark:text-blue-100 dark:border-blue-900/60";
  }

  if (channel === ThreadChannel.Other) {
    return isOutgoing
      ? "bg-zinc-800 text-white border border-zinc-900 shadow-xs dark:bg-zinc-800 dark:text-zinc-50"
      : "bg-zinc-100 text-zinc-950 border border-zinc-200 dark:bg-zinc-900/60 dark:text-zinc-100 dark:border-zinc-800";
  }

  // Gmail (default)
  return isOutgoing
    ? "bg-red-800 text-white border border-red-900 shadow-xs dark:bg-red-900 dark:text-red-50"
    : "bg-red-100 text-red-950 border border-red-200 dark:bg-red-950/50 dark:text-red-100 dark:border-red-900/60";
};

const getChannelTileClasses = (thread: ThreadWithEntry): string => {
  const isOutgoing = getMessageDirection(thread.kind) === "outgoing";
  if (isOutgoing) {
    return "bg-white/10 border-white/20 text-white";
  }

  const channel = getThreadChannel(thread);
  if (channel === ThreadChannel.LinkedIn) {
    return "bg-white/80 dark:bg-black/30 border-blue-200/60 dark:border-blue-900/40 text-blue-950 dark:text-blue-200";
  }
  if (channel === ThreadChannel.Other) {
    return "bg-white/80 dark:bg-black/30 border-zinc-200/60 dark:border-zinc-800 text-zinc-950 dark:text-zinc-200";
  }
  // Gmail (default)
  return "bg-white/80 dark:bg-black/30 border-red-200/60 dark:border-red-900/40 text-red-950 dark:text-red-200";
};

const gmailCommunicationsCount = computed(() => {
  return sortedCommunications.value.filter(
    (t) => getThreadChannel(t) === ThreadChannel.Gmail,
  ).length;
});

const linkedInCommunicationsCount = computed(() => {
  return sortedCommunications.value.filter(
    (t) => getThreadChannel(t) === ThreadChannel.LinkedIn,
  ).length;
});

const otherCommunicationsCount = computed(() => {
  return sortedCommunications.value.filter(
    (t) => getThreadChannel(t) === ThreadChannel.Other,
  ).length;
});

const availableGmailThreadTabs = computed<ThreadGroupInfo[]>(() => {
  const comms = sortedCommunications.value.filter(
    (t) => getThreadChannel(t) === ThreadChannel.Gmail,
  );
  if (!comms.length) return [];

  const threadMap = new Map<
    string,
    { label: string; sender?: string; count: number }
  >();

  for (const t of comms) {
    const threadKey = getThreadKey(t);
    if (threadKey) {
      const emailInfo = parseEmailText(t.entry?.text);
      const existing = threadMap.get(threadKey);
      const label = emailInfo.subject || `Thread #${threadKey.slice(-6)}`;
      const sender = emailInfo.from || "";
      if (existing) {
        existing.count++;
      } else {
        threadMap.set(threadKey, { label, sender, count: 1 });
      }
    }
  }

  if (threadMap.size < 2) return [];

  const tabs: ThreadGroupInfo[] = [
    {
      id: "all",
      label: "Todas as threads",
      count: comms.length,
    },
  ];

  for (const [key, data] of threadMap.entries()) {
    tabs.push({
      id: key,
      label: data.label,
      sender: data.sender,
      count: data.count,
    });
  }

  return tabs;
});

const filteredCommunications = computed<ThreadWithEntry[]>(() => {
  const comms = sortedCommunications.value;
  if (!comms.length) return [];

  if (selectedChannelTab.value === "gmail") {
    const gmailComms = comms.filter(
      (t) => getThreadChannel(t) === ThreadChannel.Gmail,
    );
    if (
      selectedGmailThreadTab.value === "all" ||
      availableGmailThreadTabs.value.length < 2
    ) {
      return gmailComms;
    }
    return gmailComms.filter(
      (t) => getThreadKey(t) === selectedGmailThreadTab.value,
    );
  }

  if (selectedChannelTab.value === "linkedin") {
    return comms.filter((t) => getThreadChannel(t) === ThreadChannel.LinkedIn);
  }

  if (selectedChannelTab.value === "other") {
    return comms.filter((t) => getThreadChannel(t) === ThreadChannel.Other);
  }

  // All: return all messages in chronological order
  return comms;
});

const showThreadDivider = (index: number): boolean => {
  const comms = filteredCommunications.value;
  if (index === 0 || comms.length === 0) return false;

  const current = comms[index];
  const prev = comms[index - 1];

  if (selectedChannelTab.value === "all") {
    const currentChannel = getThreadChannel(current);
    const prevChannel = getThreadChannel(prev);
    if (currentChannel !== prevChannel) {
      return true;
    }
    const currentKey = getThreadKey(current);
    const prevKey = getThreadKey(prev);
    return !!(currentKey && prevKey && currentKey !== prevKey);
  }

  if (
    selectedChannelTab.value === "gmail" &&
    selectedGmailThreadTab.value === "all" &&
    availableGmailThreadTabs.value.length > 1
  ) {
    const currentKey = getThreadKey(current);
    const prevKey = getThreadKey(prev);
    return !!(currentKey && prevKey && currentKey !== prevKey);
  }

  return false;
};

const getDividerLabel = (thread: ThreadWithEntry): string => {
  const channel = getThreadChannel(thread);
  if (channel === ThreadChannel.LinkedIn) {
    return "LinkedIn";
  }
  if (channel === ThreadChannel.Other) {
    return "Outro";
  }
  const emailInfo = parseEmailText(thread.entry?.text);
  if (emailInfo.subject) return `Gmail: ${emailInfo.subject}`;
  if (thread.gmailThreadId) return `Gmail: #${thread.gmailThreadId.slice(-6)}`;
  return "Gmail";
};

const onMessageInput = () => {
  props.postThreadMutation?.reset?.();
};

const startEdit = (thread: ThreadWithEntry) => {
  if (!thread.entry) return;

  editingThreadId.value = thread.id;
  editingPostId.value = thread.entry.id;

  editText.value = thread.entry.text ?? "";
};

const cancelEdit = () => {
  editingThreadId.value = null;
  editingPostId.value = null;
  editText.value = "";
};

// Gmail picker functions
const currentParticipationGmailThreadIds = computed(() => {
  if (!communicationsData.value || !selectedEventId.value) return [];
  const participation = communicationsData.value.find(
    (p) => p.event === selectedEventId.value,
  );
  return participation?.gmailThreadIds || [];
});

const currentParticipation = computed(() => {
  if (!props.participations || !selectedEventId.value) return null;
  return (
    props.participations.find((p) => p.event === selectedEventId.value) || null
  );
});

const currentParticipationStatus = computed<ParticipationStatus | undefined>(
  () => currentParticipation.value?.status,
);

const authStore = useAuthStore();
const { listThreads } = useGmailMessages();

const availableGmailThreadsCount = ref<number>(0);
const isCheckingAvailableThreads = ref<boolean>(false);

const hasManualGmailMessage = computed(() => {
  return sortedCommunications.value.some(
    (t) =>
      getThreadChannel(t) === ThreadChannel.Gmail &&
      !t.gmailMessageId &&
      !t.gmailThreadId &&
      t.kind !== ThreadKind.ThreadKindPhoneCall &&
      t.kind !== ThreadKind.ThreadKindMeeting &&
      !parseEmailText(t.entry?.text).isEmail,
  );
});

const checkAvailableGmailThreads = async () => {
  if (
    !authStore.isGoogleAuthenticated ||
    !hasManualGmailMessage.value ||
    currentParticipationGmailThreadIds.value.length > 0
  ) {
    availableGmailThreadsCount.value = 0;
    return;
  }

  isCheckingAvailableThreads.value = true;
  try {
    const res = await listThreads({
      q: props.entity.name,
      maxResults: 5,
    });
    const threads = res?.threads || [];
    const unlinked = threads.filter(
      (t) => !currentParticipationGmailThreadIds.value.includes(t.id),
    );
    availableGmailThreadsCount.value = unlinked.length;
  } catch (err) {
    console.error("Failed to check available Gmail threads:", err);
    availableGmailThreadsCount.value = 0;
  } finally {
    isCheckingAvailableThreads.value = false;
  }
};

watch(
  () => hasManualGmailMessage.value,
  (hasManual) => {
    if (hasManual) {
      checkAvailableGmailThreads();
    } else {
      availableGmailThreadsCount.value = 0;
    }
  },
  { immediate: true },
);

watch(
  () => [props.entity.id, selectedEventId.value],
  () => {
    if (hasManualGmailMessage.value) {
      checkAvailableGmailThreads();
    } else {
      availableGmailThreadsCount.value = 0;
    }
  },
);

// O aviso só pode aparecer quando se adiciona manualmente uma msg do Gmail e existem threads disponíveis onde a podemos ligar
const isContactedWithoutThread = computed(() => {
  return (
    hasManualGmailMessage.value &&
    currentParticipationGmailThreadIds.value.length === 0 &&
    availableGmailThreadsCount.value > 0
  );
});

const currentStatusLabel = computed(() => {
  if (!currentParticipationStatus.value) return "";
  return (
    humanReadableParticipationStatus[currentParticipationStatus.value] ||
    currentParticipationStatus.value
  );
});

const openGmailPicker = () => {
  gmailPickerThreadIds.value = [...currentParticipationGmailThreadIds.value];
  // Default search query is the company/speaker name
  gmailPickerDefaultQuery.value = props.entity.name;
  isGmailPickerOpen.value = true;
};

const handleGmailThreadsSave = async (threadIds: string[]) => {
  try {
    if (props.entityType === "company") {
      await updateCompanyGmailThreadIds(props.entity.id, threadIds);
    } else {
      await updateSpeakerGmailThreadIds(props.entity.id, threadIds);
    }
    // Invalidate the communications query to refresh data
    queryCache.invalidateQueries({
      key: [`${props.entityType}-communications`, props.entity.id],
    });
    // Auto-sync after linking
    await syncGmailMessages();
    availableGmailThreadsCount.value = 0;
  } catch (err) {
    console.error("Failed to update Gmail thread IDs:", err);
  } finally {
    gmailPickerThreadIds.value = [];
  }
};

// Gmail sync functionality
const { fetchMessagesForThreads } = useAutoLinkGmail();
const isSyncing = ref(false);

const syncGmailMessages = async () => {
  if (!currentParticipationGmailThreadIds.value.length) {
    return;
  }

  isSyncing.value = true;

  try {
    const allMessages = await fetchMessagesForThreads(
      currentParticipationGmailThreadIds.value,
    );

    if (allMessages.length === 0) {
      return;
    }

    // Send to backend for sync
    if (props.entityType === "company") {
      await syncCompanyGmailMessages(props.entity.id, allMessages);
    } else {
      await syncSpeakerGmailMessages(props.entity.id, allMessages);
    }

    // Refresh communications
    queryCache.invalidateQueries({
      key: [`${props.entityType}-communications`, props.entity.id],
    });
  } catch (err) {
    console.error("Failed to sync Gmail messages:", err);
  } finally {
    isSyncing.value = false;
  }
};

const saveEdit = async () => {
  const id = editingPostId.value;
  const text = editText.value.trim();
  if (!id || !text) return;

  updatePostMutation.postId.value = id;
  updatePostMutation.text.value = text;

  try {
    updatePostMutation.mutate();
  } catch (e) {
    console.error("Edit failed:", e);
    return;
  } finally {
    editingThreadId.value = null;
    editingPostId.value = null;
    editText.value = "";
    scrollToBottom();
  }
};

const requestDelete = async (thread: ThreadWithEntry) => {
  if (!thread.entry) return;
  const ok = window.confirm(
    "Delete this message? This action cannot be undone.",
  );
  if (!ok) return;

  deleteThreadMutation.threadId.value = thread.id;

  try {
    deleteThreadMutation.mutate();
  } catch (e) {
    console.error("Delete failed:", e);
  }
};

// Watch for changes in communications and scroll to bottom
watch(
  () => sortedCommunications.value,
  () => {
    scrollToBottom();
  },
  { flush: "post" },
);

// Watch for when data is first loaded and scroll to bottom
watch(
  () => communicationsData.value,
  (newData) => {
    if (newData) {
      scrollToBottom();
    }
  },
  { immediate: true },
);

// Watch for loading state changes to ensure scroll happens after data loads
watch(
  () => isLoading.value,
  (loading, wasLoading) => {
    // When loading finishes, and we have data, scroll to bottom
    if (wasLoading && !loading && sortedCommunications.value.length > 0) {
      // Add a small delay to ensure DOM has updated
      setTimeout(() => {
        scrollToBottom();
      }, 100);
    }
  },
);

// Watch for selected event changes and scroll to bottom
watch(
  () => selectedEventId.value,
  () => {
    // Small delay to let the filtered communications update
    setTimeout(() => {
      if (sortedCommunications.value.length > 0) {
        scrollToBottom();
      }
    }, 50);
  },
);

// Watch for changes in the selected channel or sub-thread tab and scroll to bottom
watch(
  () => selectedChannelTab.value,
  (newTab) => {
    if (newTab === "linkedin") {
      messageChannel.value = ThreadChannel.LinkedIn;
    } else if (newTab === "gmail") {
      messageChannel.value = ThreadChannel.Gmail;
    } else if (newTab === "other") {
      messageChannel.value = ThreadChannel.Other;
    }
    scrollToBottom();
  },
);

watch(
  () => selectedGmailThreadTab.value,
  () => {
    scrollToBottom();
  },
);

// Watch for changes in the event store
watch(
  () => eventStore.selectedEvent,
  (newEvent) => {
    if (newEvent && selectedEventId.value !== newEvent.id) {
      selectedEventId.value = newEvent.id;
    }
  },
  { immediate: true },
);

const getMessageDirection = (kind: ThreadKind): "incoming" | "outgoing" => {
  return kind === ThreadKind.ThreadKindTo ||
    kind === ThreadKind.ThreadKindTemplate ||
    kind === ThreadKind.ThreadKindPhoneCall
    ? "outgoing"
    : "incoming";
};

const getMessageAuthor = (thread: ThreadWithEntry): Author | null => {
  const direction = getMessageDirection(thread.kind);

  // For phone calls, always show the member who made the call
  if (thread.kind === ThreadKind.ThreadKindPhoneCall && thread.entry?.member) {
    return getMemberById(thread.entry.member);
  }

  if (direction === "outgoing" && thread.entry?.member) {
    return getMemberById(thread.entry?.member);
  } else if (direction === "incoming") {
    return props.entity;
  }
  return null;
};

const getAuthorAvatar = (entity: Author | null): string | undefined => {
  if (!entity) return undefined;

  if ("imgs" in entity) {
    return entity.imgs?.internal;
  } else if ("img" in entity) {
    return entity.img;
  }

  return undefined;
};

const avatarClasses = (thread: ThreadWithEntry) => {
  const direction = getMessageDirection(thread.kind);

  // People related avatars: always circular
  if (direction === "outgoing" || props.entityType === "speaker") {
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

const getKindLabel = (kind: ThreadKind): string => {
  switch (kind) {
    case ThreadKind.ThreadKindTo:
      return "Sent";
    case ThreadKind.ThreadKindFrom:
      return "Received";
    case ThreadKind.ThreadKindPhoneCall:
      return "Phone Call";
    case ThreadKind.ThreadKindMeeting:
      return "Meeting";
    case ThreadKind.ThreadKindTemplate:
      return "Template";
    default:
      return "Unknown";
  }
};

const getKindColor = (kind: ThreadKind): string => {
  switch (kind) {
    case ThreadKind.ThreadKindTo:
      return "bg-blue-500";
    case ThreadKind.ThreadKindFrom:
      return "bg-green-500";
    case ThreadKind.ThreadKindPhoneCall:
      return "bg-purple-500";
    case ThreadKind.ThreadKindMeeting:
      return "bg-orange-500";
    case ThreadKind.ThreadKindTemplate:
      return "bg-gray-500";
    default:
      return "bg-gray-400";
  }
};

const formatDate = (dateString: string): string => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInDays = Math.floor(
    (now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24),
  );

  if (diffInDays === 0) {
    return date.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
  } else if (diffInDays === 1) {
    return "Yesterday";
  } else if (diffInDays < 7) {
    return date.toLocaleDateString("en-US", { weekday: "short" });
  } else {
    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  }
};

const sendMessage = async () => {
  if (!newMessage.value.trim() || !props.postThreadMutation) return;

  try {
    // Set the thread data for the mutation
    // eslint-disable-next-line vue/no-mutating-props
    props.postThreadMutation.threadData.value = {
      text: newMessage.value,
      kind: messageKind.value,
      channel: messageChannel.value,
    };

    await props.postThreadMutation.mutate();

    newMessage.value = "";
    selectedTemplate.value = undefined;

    scrollToBottom();

    if (messageChannel.value === ThreadChannel.Gmail) {
      checkAvailableGmailThreads();
    }
  } catch (error) {
    console.error("Failed to send message:", error);
  }
};

const getMemberById = (memberId: string) => {
  return membersById.value.get(memberId);
};

const getFirstName = (fullName: string | undefined): string => {
  if (!fullName) return "Unknown";
  const parts = fullName.trim().split(/\s+/);
  return parts[0] || "Unknown";
};

const getLastName = (fullName: string | undefined): string => {
  if (!fullName) return "";
  const parts = fullName.trim().split(/\s+/);
  return parts[1] || "";
};

const getEventName = (eventId: number): string => {
  const event = eventsData.value?.data.find((e) => e.id === eventId);
  return event?.name || `Event ${eventId}`;
};

watch(
  () => selectedTemplate.value,
  (newTemplate) => {
    if (!newTemplate) return;

    const { template, variables } = newTemplate;
    openTemplateInNewTab(template, variables);

    messageChannel.value = ThreadChannel.Gmail;
    messageKind.value = ThreadKind.ThreadKindTemplate;
    newMessage.value = `Send "${templateHumanReadableNames[template]}" template`;
  },
);

const latestEvent = computed(() => {
  // Get latest event
  return eventsData.value?.data?.reduce(
    (latest, event) => {
      if (!latest || new Date(event.end || 0) > new Date(latest?.end || 0)) {
        return event;
      }
      return latest;
    },
    null as Event | null,
  );
});
</script>
