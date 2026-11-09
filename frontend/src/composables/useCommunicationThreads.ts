import { computed, ref, type ComputedRef } from "vue";
import { ThreadChannel, type ThreadWithEntry } from "@/dto/threads";
import {
  getThreadChannel,
  getThreadKey,
  parseEmailText,
  type ChannelTab,
  type ThreadGroupInfo,
} from "@/components/communications/utils";

export const useCommunicationThreads = (
  communications: ComputedRef<ThreadWithEntry[]>,
) => {
  const selectedChannelTab = ref<ChannelTab>("all");
  const selectedGmailThreadTab = ref<string>("all");

  const channelCounts = computed(() => {
    const counts = {
      [ThreadChannel.Gmail]: 0,
      [ThreadChannel.LinkedIn]: 0,
      [ThreadChannel.Other]: 0,
    };
    for (const t of communications.value) {
      counts[getThreadChannel(t)]++;
    }
    return counts;
  });

  const gmailCommunicationsCount = computed(
    () => channelCounts.value[ThreadChannel.Gmail],
  );
  const linkedInCommunicationsCount = computed(
    () => channelCounts.value[ThreadChannel.LinkedIn],
  );
  const otherCommunicationsCount = computed(
    () => channelCounts.value[ThreadChannel.Other],
  );

  const availableGmailThreadTabs = computed<ThreadGroupInfo[]>(() => {
    const comms = communications.value.filter(
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
    const comms = communications.value;
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
      return comms.filter(
        (t) => getThreadChannel(t) === ThreadChannel.LinkedIn,
      );
    }

    if (selectedChannelTab.value === "other") {
      return comms.filter((t) => getThreadChannel(t) === ThreadChannel.Other);
    }

    // All: return all messages in chronological order
    return comms;
  });

  const showThreadDivider = (index: number): boolean => {
    const comms = filteredCommunications.value;
    if (comms.length === 0) return false;

    // Show platform divider before the first message at the start of the chat
    if (index === 0) {
      if (selectedChannelTab.value === "all") return true;
      return (
        selectedChannelTab.value === "gmail" &&
        selectedGmailThreadTab.value === "all" &&
        availableGmailThreadTabs.value.length > 1
      );
    }

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

  return {
    selectedChannelTab,
    selectedGmailThreadTab,
    gmailCommunicationsCount,
    linkedInCommunicationsCount,
    otherCommunicationsCount,
    availableGmailThreadTabs,
    filteredCommunications,
    showThreadDivider,
  };
};
